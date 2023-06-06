import sys
import re


class Hint:
    def __init__(self, error, hint):
        self.error = error
        self.hint = hint


hints = [
    Hint("java.nio.file.FileSystemException:.*?Read-only file system",
         "The Kubernetes.Application.ReadOnlyFileSystem variable may need to be set to false")
]

if len(sys.argv) < 2:
    print("The first argument must be the log file to parse.")
    sys.exit(1)


def check_log(log):
    found = 0
    with open(log) as f:
        for line in f:
            for hint in hints:
                if re.search(hint.error, line) is not None:
                    print("Possible error: " + line)
                    print("Recommendation: " + hint.hint)
                    found += 1
    return found


print("Checking log file " + sys.argv[1] + " for known errors.")
errors_found = check_log(sys.argv[1])

if errors_found == 0:
    print("No errors found!")
