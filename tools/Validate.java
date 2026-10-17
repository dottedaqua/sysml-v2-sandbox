import org.omg.sysml.interactive.SysMLInteractive;
import org.omg.sysml.interactive.SysMLInteractiveResult;
import org.eclipse.xtext.validation.Issue;
import java.nio.file.*;
import java.util.*;

/**
 * Validates SysML v2 textual models against the official SysML v2 Pilot
 * Implementation parser. Used by .github/workflows/validate-models.yml and
 * usable locally.
 *
 * Usage:
 *   SYSML_LIBRARY_PATH=<path to sysml.library> \
 *   java -cp <kernel-all-jar>:<tools-class-dir> Validate <file.sysml|directory>...
 *
 * The library path must be the directory that contains "Kernel Libraries",
 * "Systems Library", and "Domain Libraries", as shipped in the
 * jupyter-sysml-kernel release artifact of the SysML v2 Pilot Implementation.
 *
 * Exit codes: 0 all files valid, 1 at least one file invalid, 2 usage error.
 */
public class Validate {
    public static void main(String[] args) throws Exception {
        String lib = System.getenv("SYSML_LIBRARY_PATH");
        if (lib == null) lib = System.getProperty("sysml.library.path");
        if (lib == null) {
            System.err.println("ERROR: SYSML_LIBRARY_PATH must point to the sysml.library directory.");
            System.exit(2);
        }
        List<String> files = new ArrayList<>();
        for (String arg : args) {
            Path p = Paths.get(arg);
            if (Files.isDirectory(p)) {
                try (var walk = Files.walk(p)) {
                    walk.map(Path::toString)
                        .filter(n -> n.endsWith(".sysml"))
                        .sorted()
                        .forEach(files::add);
                }
            } else {
                files.add(arg);
            }
        }
        if (files.isEmpty()) {
            System.err.println("ERROR: no input files.");
            System.exit(2);
        }
        SysMLInteractive kernel = SysMLInteractive.createInstance();
        kernel.loadLibrary(lib);
        boolean anyErrors = false;
        for (String file : files) {
            String text = Files.readString(Paths.get(file));
            kernel.removeResource();
            SysMLInteractiveResult result = kernel.process(text);
            List<Issue> syntax = result.getSyntaxErrors();
            List<Issue> semantic = result.getSemanticErrors();
            List<Issue> warnings = result.getWarnings();
            System.out.println("FILE " + file);
            for (Issue i : syntax)   System.out.println("  SYNTAX   line " + i.getLineNumber() + ": " + i.getMessage());
            for (Issue i : semantic) System.out.println("  SEMANTIC line " + i.getLineNumber() + ": " + i.getMessage());
            for (Issue i : warnings) System.out.println("  WARNING  line " + i.getLineNumber() + ": " + i.getMessage());
            if (result.getException() != null) System.out.println("  EXCEPTION: " + result.getException());
            boolean errs = !syntax.isEmpty() || !semantic.isEmpty() || result.getException() != null;
            anyErrors |= errs;
            System.out.println("  RESULT " + (errs ? "INVALID" : "OK")
                + " (" + syntax.size() + " syntax, " + semantic.size() + " semantic, " + warnings.size() + " warnings)");
        }
        System.out.println(anyErrors ? "VALIDATION FAILED" : "VALIDATION PASSED (" + files.size() + " files)");
        System.exit(anyErrors ? 1 : 0);
    }
}
