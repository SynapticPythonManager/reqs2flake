#!/usr/bin/env bash
#
# Permission is  hereby  granted,  free  of  charge,  to  any  person
# obtaining a copy of  this  software  and  associated  documentation
# files  (the  "Software"),  to  deal   in   the   Software   without
# restriction, including without limitation the rights to use,  copy,
# modify, merge, publish, distribute, sublicense, and/or sell  copies
# of the Software, and to permit persons  to  whom  the  Software  is
# furnished to do so.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES  OF
# MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR    PURPOSE    AND
# NONINFRINGEMENT.  IN  NO  EVENT  SHALL  THE  AUTHORS  OR  COPYRIGHT
# OWNER(S) BE LIABLE FOR  ANY  CLAIM,  DAMAGES  OR  OTHER  LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING  FROM,
# OUT OF OR IN CONNECTION WITH THE  SOFTWARE  OR  THE  USE  OR  OTHER
# DEALINGS IN THE SOFTWARE.
#
##########################License above is Equivalent to Public Domain
ISO_8601=`date -u "+%FT%TZ"` #ISO 8601 Script Start UTC Time
utc=`date -u "+%Y.%m.%dT%H.%M.%SZ"` #UTC Time (filename safe)
owd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #Path to THIS script.
######################################################################
# file: gen_dir.sh

# Use the provided argument ($1) if it exists, otherwise use $owd/numtest
if [ -z "$1" ]; then
    TargetDir="$owd/numtest"
else
    TargetDir=$1
fi

# invoke with:
# path/to/gen_dir.sh somedir

######################################################################

cd $TargetDir

# Path to your requirements file
REQUIREMENTS_FILE="requirements.bak.txt"

# Loop through each line in the file
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Extract the package name using regex to handle various version specifiers
    pkg=$(echo "$line" | sed -E 's/[<>=~!]+.*$//' | tr -d '[:space:]')

    # Run Python command to print the version
    echo -n "$pkg version: "
    python3 -c "import $pkg; print(getattr($pkg, '__version__', 'unknown'))" 2>/dev/null || echo "not installed"
done < "$REQUIREMENTS_FILE"

exit
######################################################################
cat > somefile <<'EOF'
contents
EOF
