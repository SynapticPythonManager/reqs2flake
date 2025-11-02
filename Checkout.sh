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
######################################################################
#!/usr/bin/env bash
ISO_8601=$(date -u "+%FT%TZ")   # ISO 8601 Script Start UTC Time
utc=$(date -u "+%Y.%m.%dT%H.%M%SZ") # UTC Time (filename safe)
owd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Path to THIS script
GitUrl=$1; PkgName=$2; TagName=$3
# invoke with:
# path/to/Checkout.sh git://someurl/someproject.git someproject release_0_1

BundleFile="$owd/$PkgName.bundle"

if [ ! -f "$BundleFile" ]; then
    # First time setup
    git clone --mirror $GitUrl "$PkgName.git"
else
    # Update existing mirror
    cd "$owd/$PkgName.git"
    git remote update
fi

# Create or update bundle
cd "$owd/$PkgName.git"
git bundle create "$BundleFile" --all

# Extract working copy from bundle
rm -rf "$owd/$PkgName"
git clone "$BundleFile" "$owd/$PkgName"

cd "$owd/$PkgName"
git checkout "$TagName"

exit
######################################################################
