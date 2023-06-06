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
    with open(log) as f:
        for line in f:
            for hint in hints:
                if re.search(hint.error, line) is not None:
                    print("Possible error: " + line)
                    print(hint.hint)


print("Checking log file for known errors.")
check_log(sys.argv[1])
print("Done!.")
