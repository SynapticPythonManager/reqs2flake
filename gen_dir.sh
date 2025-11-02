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

set -euo pipefail
set -e
set -x
######################################################################

mkdir $TargetDir
cd $TargetDir

cat > requirements.bak.txt <<'EOF'
numpy == 1.26.4
EOF

cat > numtest.py <<'EOF'
import numpy as np

arr_a = np.array([1, 2, 3])
arr_b = np.array([4, 5, 6])

# Element-wise addition
add_result = arr_a + arr_b
print("Addition:", add_result)

# Element-wise multiplication
mul_result = arr_a * arr_b
print("Multiplication:", mul_result)

# Scalar multiplication
scalar_mul = arr_a * 2
print("Scalar Multiplication:", scalar_mul)

# Dot product
dot_product = np.dot(arr_a, arr_b)
print("Dot Product:", dot_product)

# Sum of all elements
total_sum = np.sum(arr_a)
print("Total Sum:", total_sum)

# Mean of elements
mean_val = np.mean(arr_a)
print("Mean:", mean_val)
EOF

exit
######################################################################
cat > somefile <<'EOF'
contents
EOF
