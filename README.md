# Generate Vanity GPG Keys on macOS

![Apple Silicon](https://badgen.net/badge/icon/Apple%20Silicon?icon=apple&label)
![signed commits](https://badgen.net/static/commits/signed/green?icon=github)
![PGP signatures](https://img.shields.io/badge/PGP%20signatures-verified-0093DD?logo=gnuprivacyguard)

## Instructions

> [!Warning]
> This is a first draft set of instructions. Please analyze the code yourself and make backups of everything before proceeding.

1. Clone the repo

```bash
git clone git@github.com:adammfurman/vanity-gpg-macos.git
```

1. Make script executable

```bash
chmod +x vanity_gpg.sh
```

1. Edit the script to generate either a:
   - primary key [cert|cert sign]
   - signing subkey [cert|cert sign]
   - encryption subkey [encrypt]

```bash
code vanity_gpg.sh
```
1. Open a second terminal session to be able to manually kill the processes

Kill processes with:

```bash
pkill -f ./vanity_gpg.sh
```

To search for processes:

```bash
ps aux | grep vanity
```

1. Run script
```bash
./vanity_gpg.sh
```

## Editing the Script

The script uses gpg unattended key generation with params speciifed in via `keyparams` to generate a primary key, a signing subkey, or an ecnryption subkey.

### Primary Key

To generate a primary key pair:
- Set `ENCRYPT_KEY` to `OFF`
- Set your vanity string with regex
  - only characters `0-9` and `A-F`
- Comment out the `SUBKEY_*` variables
- Remove the `Subkey-*` parameters from the `keyparams` section
  - You can move them below the command then comment out for reuse later
- Set the parallel jobs to make use of multi-cores since CPU generation is inefficient
  - Do not exceed or match your cores
  - I recommend < core count
- Set the rest of the variables at the top
  - Recommendation: Set you UID variables the same for all keys/subkeys
- Run the script
- Export the secret and public keys via the commands given in the output
- Delete the `match_file.txt` and `~/vanity_gpg_dir` if you want to run the script again

### Signing Subkey

- Set `ENCRYPT_KEY` to `OFF`
- Set your vanity string regex
  - only `0-9` and `A-F`
- Uncomment all `SUBKEY_*` variables
  - set them to your preferences
- Make sure the `Subkey-*` params are back in the `keyparams` section
- Set all your variables
- Run the script
- Export the secret and public key via the commands given in the output
- Delete the `match_file.txt` and `~/vanity_gpg_dir` if you want to run the script again

### Encryption Subkey

- Set `ENCRYPT_KEY` to `ON`
- Set your vanity string regex
  - only `0-9` and `A-F`
- Uncomment all `SUBKEY_*` variables
  - set them to your preferences
  - set `SUBKEY_USAGE=encrypt`
- Make sure the `Subkey-*` params are back in the `keyparams` section
- Set all your variables
- Run the script
- Export the SECRET SUBKEY with the option:
  - `--export-secret-subkey`
- Export the public key with the commmand given in the output
- Delete the `match_file.txt` and `~/vanity_gpg_dir` if you want to run the script again


