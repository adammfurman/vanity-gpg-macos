#!/bin/bash

# ---- Error Handling --------------------
set -euo pipefail


# ---- Set Global Variables --------------------
# Unattendaded key generation manual: https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html
# Customize these:

# Set to ON to match against encryption subkey fpr [ON|OFF]
ENCRYPT_KEY="ON"

# Regex pattern for fingerprint (uppercase hex, e.g., "^0000.{32}0000$" for starting and ending in 0000
PATTERN="^00.{36}00$"
KEY_TYPE=default
KEY_CURVE=ed25519
KEY_USAGE="cert"
SUBKEY_TYPE=ECC          
SUBKEY_CURVE=cv25519
SUBKEY_USAGE=encrypt
NAME="First Last"
EMAIL="email@example.org"
PASSPHRASE="password"
EXPIRE="0"

# Parallel processes (adjust to < your CPU cores)
JOBS=8


# ---- GPG Params --------------------
# Batch file template for gpg --gen-key
# Remove Subkey-* if not generating subkeys/encryption key
cat > keyparams <<EOF
Key-Type: $KEY_TYPE
Key-Curve: $KEY_CURVE
Key-Usage: $KEY_USAGE
Subkey-Type: $SUBKEY_TYPE
Subkey-Curve: $SUBKEY_CURVE
Subkey-Usage: $SUBKEY_USAGE
Name-Real: $NAME
Name-Email: $EMAIL
Expire-Date: $EXPIRE
Passphrase: $PASSPHRASE
%commit
EOF


# ---- Begin Script --------------------
echo "🔎 Searching for fingerprint matching: $PATTERN (uppercase hex regex)"
echo "Running $JOBS parallel jobs..."


# ---- Key Generation Function --------------------
# Function for one generation attempt
generate_one() {
    local tempdir=$(mktemp -d)
    GNUPGHOME="$tempdir" gpg --batch --quiet --gen-key keyparams >/dev/null 2>&1
    local find_fpr
    if [[ $ENCRYPT_KEY =~ "ON" ]]; then
        find_fpr="tail -n1"
    else
        find_fpr="head -n1"
    fi
    local fpr=$(GNUPGHOME="$tempdir" gpg --batch --quiet --list-keys --with-colons | grep ^fpr | bash -c "$find_fpr" | cut -d: -f10)
    if [[ $fpr =~ $PATTERN ]]; then
        echo ""
        echo "✅ Found matching key: $fpr"
        echo "$fpr" > fpr.txt
        echo "$tempdir" > match_found.txt
        return
    fi
    rm -rf "$tempdir"
}

# Run in parallel
for ((i=1; i<=JOBS; i++)); do
    while true; do
        if [[ -f match_found.txt ]]; then
            echo "Match already found by another job. Stopping this worker." # visual feedback to stopping jobs
            exit 0
        fi
        generate_one
    done &
done

# Wait for all background jobs to finish
wait


# ---- Final Output --------------------
# Closing process
if [[ -f match_found.txt ]]; then
    MATCH_DIR=$(cat match_found.txt)
    mv "$MATCH_DIR" "$HOME/vanity_gpg_dir"
    MATCH_DIR="$HOME/vanity_gpg_dir"
    fpr=$(cat fpr.txt)
    echo ""
    echo "🎉 Search complete! Keyring preserved at: $MATCH_DIR"
    echo "You can now export it manually, e.g.:"
    echo "   GNUPGHOME=\"$MATCH_DIR\" gpg --armor --export-secret-keys > $HOME/$fpr.sec.asc"
    echo "   GNUPGHOME=\"$MATCH_DIR\" gpg --armor --export > $HOME/$fpr.pub.asc"
    echo ""
    GNUPGHOME="$MATCH_DIR" gpg --list-keys --with-subkey-fingerprints
else
    echo "No match found (script ended abnormally)."
    rm -f match_found.txt fpr.txt  # in case of abnormal exit
fi

# ---- Info --------------------
# To kill all processes: pkill -f ./vanity_gpg_subkey.sh
# To search for processes: ps aux | grep vanity
# To run script multiple times, delete match_file.txt and, optionally, ~/vanity_gpg_dir