#!/bin/bash

DEBUG=false

USAGE="
-- Encryption options --
    decrypt   - Decrypt the given file using the specified keyfile and journal entry to stdout.
                      Required Flags:
		      --entry       : Specify the file entry to decrypt using the specified keyfile.
		      --keyfile     : Supply a key file containing the user generated password
                                      for the symeteric encryption of given journal entry.
                      --key-from-url: Supply a URL containing encrypted symetric key for decryption
                      --proxy       : Should proxy via Tor be enabled for key-from-url operations? 
                                      Enabling this option allows use of tor hidden service urls.
    encrypt   - Encrypts a given file using decrypted symetric key specified.
                      Optional flags:
		      --type	    : Specify the type of journal entry to encrypt (new or archive)
				      The default assumes type 'new'
                      --config_path : Supply a path to the files root path if not already in current path
                      --keyfile     : Supply a key file containing the user generated password
                                      for the symeteric encryption of given journal entry.
				      Default assumes 'key.asc' in current path
                      --key-from-url: Supply a URL containing encrypted symetric key for decryption
                      --proxy       : Should proxy via Tor be enabled for key-from-url operations? 
                                      Enabling this option allows use of tor hidden service urls.
    backup    - Creates an encrypted backup archive
                      Optional flags:
                      --config_path : Supply a path to the journal root path if not already in current path
		      --backup_path : Supply a path of where to write the encrypted tar archive to
		      		      Default assumes 'HOME/jbackup' which should be an external mounted device
                      --keyfile     : Supply a key file containing the password for the symeteric encryption
		      		      of the backup archive to be created.
                                      Default assumes 'backup_key.asc' in current path
                      --key-from-url: Supply a URL containing encrypted symetric key for archive encryption
                      --proxy       : Should proxy via Tor be enabled for key-from-url operations? 
                                      Enabling this option allows use of tor hidden service urls.

-- Misc options --
    version    - Shows the script version
    newkey     - Generates a new symetric key for a given recipient
    newdraft   - Create a new draft file for the current day.
"

newDraft(){
	safety_check
	if [ -f $draftfile ];
	then
		fail_out "Draft file aready exists"


	else
		echo $(date +%A%t%B%t%d%t%Y%n) > $draftfile 2>&1
		success_msg "New draft completed successfully... Exiting"

	fi
}


safety_check(){
debug_msg "${CURRENT_FP}"
debug_msg "${BACKUP_FP}"
debug_msg "Decrypted Password: $passwd"
debug_msg "Base Path: ${BASE}"
debug_msg "Current Path: ${JOURNAL_BASE}"
debug_msg "Current Backup Path: ${BACKUP_FP}"

## Check to see if ${CURRENT_FP} is set, if not set set ${BASE} to current path
if [[ -z ${CURRENT_FP+x} ]]; then
	BASE="$(pwd -P)"
	[[ ! -z ${BASE} ]] || error_msg "Safety Check: Could not set BASE"
else
	BASE=${CURRENT_FP}
fi

## Check to see if ${BACKUP_FP} is set, if not set ${BACKUP} to /backup
if [[ -z ${BACKUP_FP+x} ]]; then
	BACKUP="${HOME}/jbackup"
	[[ ! -z ${BACKUP} ]] || error_msg "Safety Check: Could not set BACKUP path"
else
	BACKUP=${BACKUP_FP}
fi

JOURNAL_BASE="${BASE}/$(date +%Y)/$(date +%B)"
efile="${JOURNAL_BASE}/$(date +%b_%d).asc"
draftfile="${BASE}/draft/$(date +%F).txt"

debug_msg "New Base Path: ${BASE}"
debug_msg "New Current Path: ${JOURNAL_BASE}"
debug_msg "New Backup Path: ${BACKUP}"

if [[ ! -d "${JOURNAL_BASE}" || ! -d "${BASE}/draft/" ]]; then
	info_msg "Creating paths.."
	mkdir -p ${BASE}/draft/ || error_msg "Safety Check: Failed to create DRAFT directory"
	mkdir -p ${JOURNAL_BASE} || error_msg "Safety Check: Failed to create BASE directory"
	stopped_msg "Try again"
	exit 0
elif [ -f $efile ]; then
	if [ -s $efile ]; then
		fail_out "Safety Check: Encrypted Journal exists and not empty"
	else
		error_msg "Saftey Check: Encrypted Journal exists but empty..."
		exit 2;
	fi
else
	info_msg "Safey Checks passed, continuing..."
	lastBackup
	return 0
fi
}

encryptDraft(){
	safety_check
	debug_msg $draftfile
	info_msg "Formatting File"
	if [ -f $draftfile ]; then

		doEncrypt
	else
		 error_msg "Today's Draft is missing, please check current path..."
	fi
	if [ ! -z "$(ls -A ${BASE}/draft/)" ]; then
		warn_msg "Draft directory not empty!"
		read -r -p "Would you like to encrypt old draft entries? [Y/n] " ans
		case $ans in
			[yY]) encryptOld ;;
			[nN])
				exit 0
				;;
			*)
				fail_out "Invalid Input"
				;;
			esac

	else
		success_msg "There were no file candiates for encryption found... Exiting"
		exit 0
	fi
}

shredSource(){
	info_msg "Shredding Draft..."
       	if [[ -f $efile ]]
        then
                shred -ufz -n 35 $draftfile || warn_msg "Could not complete shred operation"
                success_msg "Shred action completed successfully"
        else
		fail_out "Shred Action failed, please check previous encryption operation"
        fi
}

encryptOld() {
	safety_check
	for draft in $(ls -A ${CURRENT_FP}/draft/*.txt);
	do
		local date=echo $file |cut -f1 -d'.'
		Year=`date -d "$date" +%Y`
		Month=`date -d "$date" +%B`
		Day=`date -d "$date" +%b_%d`
		efile="${BASE}/$Year/$Month/$Day.asc"
		if [[ ! -d ${BASE}/$Year/$Month ]]; then
			mkdir -p ${BASE}/$Year/$Month || fail_out "Could not create path..."
		fi
		doEncrypt
	done
	success_msg "Completed archive encryption operations"
}


doEncrypt(){
	info_msg "Encrypting Entry..."
	$(cat $draftfile | fold -s -w 72 | gpg2 -ac --batch --pinentry-mode loopback --passphrase $passwd -o $efile)
        info_msg "Journal entry successfully encrypted... "
	## Possible at later time to add date/time check to ensure that the created file is actualy a new file, not old.
	if [[ -f $efile && -s $efile ]]; then
		shredSource || warn_message "Unable to complete shred action"
	elif [[ -f $efile && ! -s $file ]]; then
		fail_out "An error occured, encrypted journal is empty... "
	else
		fail_out "Encrypted Journal Entry currently exists, please verify destination path."
	fi
}

randpw(){ < /dev/urandom tr -s -dc [:graph:] [:alnum:]| head -c${1:-64};echo;}

newKey(){
	secret=$(randpw)
	info_msg "Where should we output the new key? Specify a location or type stdout to output to screen"
	read -p "Enter Absolute Path: " keylocation
	read -p "Who is recipient of the key? " recipient
	debug_msg "Generated Key is: $secret"
	[[ $keylocation == /* || $keylocation == "stdout" ]] || fail_out "You did not give an absolute path, we are unable to resolve relative paths"
	if [[ $keylocation == "stdout" ]]; then
		echo $secret | gpg2 -ea -R $recipient -
	else
		local keyfile=$(readlink -f $keylocation)
		debug_msg "Keyfile: $keyfile"
		[[ ! -z $keyfile ]] || error_msg "Keyfile path empty"
		echo $secret | gpg2 -ea --batch -o $keyfile -R $recipient -

		if [[ -f $keyfile ]]; then
			success_msg "Secret Key successfully written to $keyfile"
		else
			error_msg "Unable to write secret to file."
		fi
	fi
}

encrypt(){
	checkKey
	if [[ ! -z $TYPE && $TYPE == "new" ]]; then
		encryptDraft
	elif [[ ! -z $TYPE && $TYPE == "archive" ]]; then
		encryptOld
	else
		info_msg "No type specififed, assuming new"
		encryptDraft
	fi
}

decrypt(){
	checkKey
	debug_msg "File Entry: ${ENTRY}"
	debug_msg "Password: $passwd"
	printf "$(gpg2 -dq --batch --pinentry-mode loopback --passphrase "$passwd" ${ENTRY})\n"
}

backup(){
	checkKey
	warn_msg "Unit Tests for BACKUP Incomplete"
	safety_check
	local DIR="${BASE}/draft/"
	if [ ! "$(ls -A $DIR)" ]; then
		info_msg "Backup of ${BASE} to ${BACKUP} in progress"
		#tar -cvz ${BASE} | gpg2 -b -c --batch --pinentry-mode loopback --passphrase $passwd -o ${BACKUP}/backup.tgz.gpg
	else
		warn_msg "Take action $DIR is not Empty"
	fi
}
lastBackup(){
	local newest=$(find ${BACKUP} -type f -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1)
	if [[ ! -z ${newest} ]]; then
	local last=$(date -r ${newest} +%s)
	local cur=$(date +%s)
	local sub=$((${cur}-${last}))
	local nxt=$((${cur}+1209600))
		if [[ ${sub} -ge 1209600 ]]; then
			warn_msg "Last backup is older than TWO WEEKS! Run backup ASAP!!"
		else
			info_msg "Next backup should not exceed $(date -d @${nxt})"
		fi
	else
		fail_out "Could not find latest backup, is ${BACKUP} mounted?"
	fi
}

checkKey(){
if [[ -n ${KEYFILE} ]]; then
	passwd=`gpg2 -dq --batch "${KEYFILE}" | tr -d '[:space:]'`
elif [[ -n ${KEY_URL} ]]; then
	if [[ -n ${PROXY} && ${PROXY,,} == 'true' || ${PROXY,,} == 'yes' ]]; then
		debug_msg "URL: ${KEY_URL}"
		debug_msg "Proxy enabled: ${PROXY}"
		passwd=`curl -s --socks5-hostname '127.0.0.1:9050' ${KEY_URL} | gpg2 -dq --batch - | tr -d '[:space:]'`
	else
		passwd=`curl -s ${KEY_URL} | gpg2 -dq --batch - | tr -d '[:space:]'`
	fi
else
	fail_out "Key option is required, specify key."
fi
}

#: Mimic codes
GREEN='\e[0;32m'
CYAN='\e[0;36m'
YELLOW='\e[1;33m'
RED='\e[0;31m'
BLUE='\e[1;94m'
WARN='\e[1;5;31m'
NC='\e[0m' # No Color

ERROR_SIG="[${RED}ERROR${NC}]\n"
INFO_SIG="[${GREEN}INFO${NC}]\n"
STOPPED_SIG="[${YELLOW}STOPPED${NC}]\n"
SUCCESS_SIG="[${CYAN}SUCCESS${NC}]\n"
DEBUG_SIG="[${BLUE}DEBUG${NC}]\n"
WARN_SIG="[${WARN}WARNING${NC}]\n"
#: Helper functions
usage() {
    echo "Usage: $0 <command>"
    echo "${USAGE}"
    exit 1
}

error_msg() {
    strlen=${#1}
    cols=$((`tput cols` - $strlen))
    printf "%${strlen}s %${cols}b" "$1" ${ERROR_SIG}
}

info_msg() {
    strlen=${#1}
    cols=$((`tput cols` - $strlen))
    printf "%${strlen}s %${cols}b" "$1" ${INFO_SIG}
}

stopped_msg() {
    strlen=${#1}
    cols=$((`tput cols` - $strlen))
    printf "%${strlen}s %${cols}b" "$1" ${STOPPED_SIG}
}

success_msg() {
    strlen=${#1}
    cols=$((`tput cols` - $strlen))
    printf "%${strlen}s %${cols}b" "$1" ${SUCCESS_SIG}
}

debug_msg(){
    strlen=${#1}
    cols=$((`tput cols` - $strlen))
    if [[ ${DEBUG} == true ]]; then
	    printf "%${strlen}s %${cols}b" "$1" ${DEBUG_SIG}
    fi
}
warn_msg(){
    strlen=${#1}
    cols=$((`tput cols` - $strlen))
    printf "%${strlen}s %${cols}b" "$1" ${WARN_SIG}
}
fail_out(){
    error_msg "$@"
    exit 1
}

check_uid() {
    if [[ $(id -u) -lt 1000 ]] ; then echo "Please run as USER" ; exit 1 ; fi
}

### ARGUMENTS ###
handle_args(){

  #: The first argument is the operation being performed (e.g. install, uninstall, or reinstall).
  local _op=$1
  shift

  # As long as there is at least one more argument, keep looping
  while [[ $# -gt 0 ]]; do
      local _key="$1"
      case "${_key}" in
          -t|--type)
            shift
            TYPE="$1"
          ;;
            -t=*|--type=*)
            TYPE="${_key#*=}"
          ;;
          -k|--keyfile)
            shift
            KEYFILE="$1"
          ;;
          -k=*|--keyfile=*)
            KEYFILE="${_key#*=}"
          ;;
          -u|--key-from-url)
            shift
            KEY_URL="$1"
          ;;
          -u=*|--key-from-url=*)
            KEY_URL="${_key#*=}"
          ;;
          -c|--config_path)
            shift
	    CURRENT_FP="$1"
          ;;
          -c=*|--config_path=*)
	    CURRENT_FP="${_key#*=}"
          ;;
          -b|--backup_path)
            shift
	    BACKUP_FP="$1"
	  ;;
          -b|--backup_path)
            BACKUP_FP="${_key#*=}"
	  ;;
	  -e|--entry)
            shift
            ENTRY="$1"
          ;;
          -e=*|--entry=*)
            ENTRY="${_key#*=}"
          ;;
	  -p|--proxy)
            shift
            PROXY="$1"
          ;;
          -p=*|--proxy=*)
            PROXY="${_key#*=}"
          ;;
          *)
            # Error on unknown options
            fail_out "Unknown option '${_key}'"
          ;;
      esac

      # Shift after checking all the cases to get the next option
      shift
  done
}

############
### MAIN ###
############
[ $# -lt 1 ] && usage

check_uid

case "$1" in
    #: main opts
    encrypt)
        handle_args "$@"
        encrypt
        ;;
    decrypt)
	handle_args "$@"
        decrypt
        ;;
    backup)
	handle_args "$@"
	backup
	;;
    #: misc opts
    version)
        version
        ;;
    newkey)
	newKey
        ;;
    newdraft)
	newDraft
	;;
    help)
        usage
        ;;
    *)
        usage
        ;;

esac
exit 0
