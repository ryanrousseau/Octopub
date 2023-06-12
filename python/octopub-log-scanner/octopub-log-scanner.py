# This script provides a simple example of scanning log files to look for known issues and suggest common fixes.
# It is designed to demonstrate the self-service functionality of runbooks.

import sys
import re


class Hint:
    """
    A hint includes a regular expression that matches some known text in a log file, and a hint
    indicating a possible solutions.
    """
    def __init__(self, error, hint):
        self.error = error
        self.hint = hint


# This is the database of hints
hints = [
    Hint("java.nio.file.FileSystemException:.*?Read-only file system",
         "The Kubernetes.Application.ReadOnlyFileSystem variable may need to be set to false")
]

# The name of the log file must be passed in as the first argument.
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
