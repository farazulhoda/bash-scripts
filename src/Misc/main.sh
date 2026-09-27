#!/bin/bash
set -euo pipefail

FILENAME="${1:-main.sh}"
echo "#!/bin/bash" > "$FILENAME"
chmod +x "$FILENAME"
vim "$FILENAME"
