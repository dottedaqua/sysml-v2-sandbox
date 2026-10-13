
/*============================================================================
  Test_System
  Reference example model for the SysML v2 behavior simulator.

  Status: DRAFT. The textual syntax follows the SysML v2 Pilot Implementation
  notation to the best available accuracy and will be validated against the
  Pilot parser. The authoritative input for the simulator is the JSON graph
  (semantic profile D20), not this text; the model serves as the human-readable
  reference and as the source for the provisional schema.

  Conventions demonstrated (references to the semantic profile):
  - One state machine per part as root behavior ........... Convention 1, D16
  - Transitions via accept, events from transmit .......... Convention 2
  - Entry / do / exit and completion transitions ......... D22
  - Structured items; payload attributes cross bindings ... D26, D27
  - Ports with multiple typed items ...................... D25
  - Flow delegation and value aliasing via bind .......... D26
  - Decision with explicit else ......................... Convention 8
  - Explicit parallelism via fork and join .............. Convention 9, D29
  - Predefined actions, single usage, perform ........... Convention 10
  - Self-directed events ............................... D28
  - Indexed references through multiplicity ............. D30
  - Unexpected-event convention (else to error state) ... Convention 15
  - Opaque actions trigger the interactive pause ........ D11
  - Do-behavior preemption on transitions ............... D23
============================================================================*/

package Test_System {

    private import ScalarValues::*;

    //----------------------------------------------------------------------
    // Items (structured; objects and information, no streams)
    //----------------------------------------------------------------------

    item def Measurement {
        attribute value : Real;
    }

    item def ErrorReport {
        attribute errorCode : Integer;
        attribute severity  : Integer;
    }

    item def PollRequest {
    }

    item def FaultIndication {
    }

    item def ShutdownCommand {
        attribute reason : String;
    }

    //----------------------------------------------------------------------
    // Ports (multiple typed items per port, D25)
    //----------------------------------------------------------------------

    port def OperatorPort {
        in item shutdownCommand : ShutdownCommand;
    }

    port def SensorLinkPort {
        in item pollResponse : Measurement;
        in item errorReport  : ErrorReport;
        out item pollRequest : PollRequest;
        out item shutdownCommand : ShutdownCommand;
    }

    port def SensorDiagPort {
        out item pollResponse : Measurement;
        out item errorReport  : ErrorReport;
        in item pollRequest   : PollRequest;
        in item shutdownCommand : ShutdownCommand;
    }

    //----------------------------------------------------------------------
    // Action definitions (predefined; exactly one usage each, Convention 10)
    //----------------------------------------------------------------------

    // Opaque bodies: the simulator pauses (D11) and the user supplies outputs.

    action def InitComms {
        out attribute commsOk : Boolean;
    }

    action def InitStorage {
        out attribute storageOk : Boolean;
    }

    action def Initialize {
        // Explicit parallelism (Convention 9); implicit join on completion (D29).
        fork
            action initComms : InitComms;
            action initStorage : InitStorage;
        join
        assign self.ready := initComms.commsOk and initStorage.storageOk;
    }

    action def EvaluateMeasurement {
        in item m : Measurement;
        out attribute fault : Boolean = m.value > self.threshold;
    }

    action def ReportFault {
        // Self-directed event (D28): triggers the transition to FaultHandling.
        transmit f : FaultIndication to self;
    }

    action def MonitorSensors {
        loop {
            // Poll both sensor instances explicitly (indexed sends, D30).
            transmit pr1 : PollRequest via self.sensorLinks[1];
            transmit pr2 : PollRequest via self.sensorLinks[2];

            // Accept one response per cycle. If both port queues hold a
            // response, the order is resolved interactively (D10).
            accept m : Measurement via self.sensorLinks;

            evaluate : EvaluateMeasurement(m);

            decision d;
            if evaluate.fault then
                reportFault : ReportFault;
            else
                // Value within limits: continue monitoring.
            }
        }
    }

    action def HandleFault {
        // Opaque (D11): the user supplies the handling result at runtime.
        out attribute handled : Boolean;
    }

    action def LogError {
        assign self.ready := false;
    }

    action def ShutDownSensors {
        transmit sd1 : ShutdownCommand via self.sensorLinks[1];
        transmit sd2 : ShutdownCommand via self.sensorLinks[2];
    }

    action def MeasureAndReport {
        // Opaque measurement value (D11): user-supplied at runtime.
        transmit response : Measurement via self.diag;
    }

    action def SelfTest {
        // Opaque (D11): user decides at runtime whether a fault occurred.
        out attribute fault : Boolean;
    }

    action def FaultWatch {
        loop {
            selfTest : SelfTest;
            decision d;
            if selfTest.fault then
                transmit f : FaultIndication to self;   // D28
            else
                // No fault detected: keep watching.
            }
        }
    }

    action def ReportSensorError {
        transmit e : ErrorReport via self.diag;   // payload attributes user-supplied (D11)
    }

    //----------------------------------------------------------------------
    // Controller
    //----------------------------------------------------------------------

    part def Controller {
        port operatorLink : OperatorPort;
        port sensorLinks  : SensorLinkPort[2];   // one port instance per sensor, D25/D30

        attribute ready    : Boolean = false;
        attribute threshold : Real = 100.0;

        do state controllerStates : ControllerStates;

        state def ControllerStates {
            initially Booting;

            state Booting {
                entry initialize : Initialize;
                then Monitoring;   // completion transition (D22)

                accept e : ErrorReport via self.sensorLinks else then ErrorHandling;   // Convention 15
                accept s : ShutdownCommand via self.operatorLink then Done;
            }

            state Monitoring {
                do monitor : MonitorSensors;   // preempted on transition (D23)

                accept f : FaultIndication then FaultHandling;   // from ReportFault (D28)
                accept e : ErrorReport via self.sensorLinks [e.severity > 10] then FaultHandling;
                accept e : ErrorReport via self.sensorLinks else then ErrorHandling;   // Convention 15
                accept s : ShutdownCommand via self.operatorLink then Done;
            }

            state FaultHandling {
                entry handleFault : HandleFault;
                then Monitoring;   // return after handling (D22)

                accept e : ErrorReport via self.sensorLinks [e.severity > 10] then FaultHandling;
                accept e : ErrorReport via self.sensorLinks else then ErrorHandling;
                accept s : ShutdownCommand via self.operatorLink then Done;
            }

            state ErrorHandling {
                entry logError : LogError;   // explicit error state (Convention 15)

                accept e : ErrorReport via self.sensorLinks then ErrorHandling;
                accept s : ShutdownCommand via self.operatorLink then Done;
            }

            final state Done {
                entry shutDownSensors : ShutDownSensors;
            }
        }
    }

    //----------------------------------------------------------------------
    // Sensor
    //----------------------------------------------------------------------

    part def Sensor {
        port diag : SensorDiagPort;
        attribute active : Boolean = true;

        do state sensorStates : SensorStates;

        state def SensorStates {
            initially Idle;

            state Idle {
                accept p : PollRequest via self.diag then Measuring;
                accept s : ShutdownCommand via self.diag then Off;
            }

            state Measuring {
                entry measure : MeasureAndReport;
                do faultWatch : FaultWatch;   // may transmit FaultIndication to self (D28); preempted on transition (D23)

                accept p : PollRequest via self.diag then Measuring;
                accept f : FaultIndication then SensorError;
                accept s : ShutdownCommand via self.diag then Off;
            }

            state SensorError {
                entry reportSensorError : ReportSensorError;
                accept s : ShutdownCommand via self.diag then Off;
            }

            final state Off;
        }
    }

    //----------------------------------------------------------------------
    // System: composition, binds (D26), indexed connections (D30)
    //----------------------------------------------------------------------

    part def DiagnosticUnit {
        // Value aliasing across levels (D26 ValueBind).
        attribute systemReady : Boolean = false;
        bind systemReady = controller.ready;

        // System-level port delegating to the controller boundary port
        // (D26 FlowBind); the routing layer follows the delegation.
        port extDiag : OperatorPort;
        bind extDiag = controller.operatorLink;

        part controller : Controller;
        part sensors : Sensor[2];   // full multiplicity instantiation (D5)

        // Indexed connections: each sensor instance is addressed through
        // its own controller port instance (D30).
        connect controller.sensorLinks[1] to sensors[1].diag;
        connect controller.sensorLinks[2] to sensors[2].diag;
    }
}
