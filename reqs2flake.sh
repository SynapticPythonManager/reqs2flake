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
# file: reqs2flake.sh
if [ -z "$1" ]; then
    TargetDir="$owd/numtest"
    # creates numtest dir with numtest.py and requirements.bak.txt
    rm -rf $TargetDir
    $owd/gen_dir.sh
else
    TargetDir=$1
fi
# invoke with:
# path/to/reqs2flake.sh somedir

set -euo pipefail
set -e
set -x
######################################################################

cd $TargetDir

if [[ ! -f requirements.bak.txt ]]; then
    echo "requirements.bak.txt not found in $(pwd)"
    return 1
fi
# uv pip compile requirements.bak.txt -o requirements.txt --upgrade
# uv pip compile requirements.bak.txt -o requirements.txt --upgrade --no-binary ale-py
uv pip compile requirements.bak.txt -o requirements.txt --upgrade --prerelease=allow

# ###################################
# if [ -f requirements.bak.txt ]; then
#   echo "File 'requirements.bak.txt' already exists. Skipping creation."
# else
#   echo "you need to add imports to requirements.bak.txt"
#   cat > requirements.bak.txt <<'EOF'
# 
# EOF
# fi

if [ -f flake.nix ]; then
  echo "File 'flake.nix' already exists. Skipping creation."
else
cat > flake.nix <<'EOF'
# flake.nix
{
  description = "My Python App with Nix and uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Core pyproject-nix ecosystem tools
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";

    # Ensure consistent dependencies between these tools
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-build-systems.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
    pyproject-build-systems.inputs.pyproject-nix.follows = "pyproject-nix";
  };

  outputs = { self, nixpkgs, flake-utils, uv2nix, pyproject-nix, pyproject-build-systems, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312; # Your desired Python version

        # 1. Load Project Workspace (parses pyproject.toml, uv.lock)
        workspace = uv2nix.lib.workspace.loadWorkspace {
          workspaceRoot = ./.; # Root of your flake/project
        };

        # 2. Generate Nix Overlay from uv.lock (via workspace)
        uvLockedOverlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel"; # Prefer wheels to avoid building from sdists
        };

        # 3. Placeholder for Your Custom Package Overrides
        myCustomOverrides = final: prev: {
          /* Add overrides here only if a specific package fails with wheels */
        };

        # 4. Construct the Final Python Package Set
        pythonSet =
          (pkgs.callPackage pyproject-nix.build.packages { inherit python; })
          .overrideScope (nixpkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.default # For build tools
            uvLockedOverlay                          # Your locked dependencies
            myCustomOverrides                        # Your fixes
          ]);

        # --- This is where your project's metadata is accessed ---
        projectNameInToml = "ex-reqs-shell"; # MUST match [project.name] in pyproject.toml!
        thisProjectAsNixPkg = pythonSet.${projectNameInToml};
        # ---

        # 5. Create the Python Runtime Environment
        appPythonEnv = pythonSet.mkVirtualEnv 
          (thisProjectAsNixPkg.pname + "-env") 
          workspace.deps.default; # Uses deps from pyproject.toml [project.dependencies]

      in
      {
        # Development Shell
        devShells.default = pkgs.mkShell {
          packages = [
            appPythonEnv
            pkgs.ruff
            pkgs.uv
            pkgs.cmake
            pkgs.SDL2
          ];
          shellHook = '' ''; # custom shell hooks
        };
      }
    );
}
EOF
fi

gen_toml() {


set -euo pipefail

# Format dependencies from requirements.bak.txt for toml
deps=$(cat requirements.bak.txt | sed 's/^/"/; s/$/",/' | tr '\n' '\n')

cat > pyproject.toml <<EOF
#pyproject.toml
[project]
name = "ex-reqs-shell"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
$deps
]

[tool.uv.sources]
torch = { index = "pytorch-cpu" }

[[tool.uv.index]]
name = "pytorch-cpu"
url = "https://download.pytorch.org/whl/cpu"
explicit = true
EOF

  echo ">>> generating uv.lock with CPU-only Torch"
  uv lock --upgrade

}

gen_toml

bakhash=$(sha256sum $TargetDir/requirements.bak.txt | awk '{print $1}')
bakhash=${bakhash: -8}
echo "$bakhash"


handle_git() {
cd "$TargetDir"

FILES="flake.nix pyproject.toml uv.lock requirements.bak.txt"

if [ ! -d ".git" ]; then
  echo ">>> Initializing local git repo for flake"
  git init -b main
  git add $FILES
  git commit -m "init local flake - reqs2flake.sh preparing $bakhash for development"
else
  echo ">>> Git repo already exists in $TargetDir, checking for changes"
  # Stage any new or modified files
  git add $FILES

  # Only commit if there are staged changes
  if git diff --cached --quiet; then
    echo ">>> No changes to commit"
  else
    git commit -m "update local flake - reqs2flake.sh refreshing $bakhash"
  fi
fi
}

handle_git

exit
## end of script
################################################################################
# example usage #run the file we are in
path/to/reqs2flake.sh somedir
cd somedir
nix develop --impure
### imports should work
python somefile.py
################################################################################
git clone reqs2flake && cd ./reqs2flake
cd ~/sync/reqs2flake && ./reqs2flake.sh && cd ./numtest && nix develop --impure

cd ~/sync/reqs2flake && ./versions.sh
# python3 -c "import numpy; print(numpy.__version__)"
#occasionally try:
rm -rf ~/.cache/uv
rm -rf ~/.cache/pypoetry
rm -rf ~/.cache/pip
