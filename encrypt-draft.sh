#!/bin/bash


## Decryption Process is a follows
## gpg2 -dq --batch --pinentry-mode loopback --passphrase $(gpg2 -dq key.asc) <file to decrypt>

#passwd=`gpg2 -dq $(pwd -P)/key.asc`
jpath="$(date +%Y)/$(date +%B)"
efile="$(date +%b_%d).asc"
outfile="$(pwd -P)/$jpath/$efile"

encrypt_journal(){
	echo "Formatting File"
	draft=$(fold -s -w 72 $entry)
	if [ -f $outfile ]
        then
            if [ -s $outfile ]
            then
                echo "File exists and not empty"
		exit 1;
            else
                echo "File exists but empty"
		exit 2;
            fi
        else
		echo "Encrypting Entry..."
		$(cat $entry | fold -s -w 72 | gpg2 -ac --batch --pinentry-mode loopback --passphrase $passwd -o $outfile)
		echo -e "Journal entry successfully encrypted... \nShredding Draft..."
		if [[ -f $outfile ]]
		then
			shred -ufz -n 35 $entry
			echo "Shred action completed successfully"
		else
			"Shred Action failed, please check previous operation"
			exit
		fi
	fi
}

function display_help {
	echo -e "Usage: $0 [options [parameters]]\n"
	echo -e "\n"
	echo -e "Options:\n"
	echo -e "-k|--key [keyfile], Specify the ecnrypted symetric key file to decrypt\n"
	echo -e "-n|--new-key, Generate a new key with a randomdly generated passprahse.\n"
	echo -e "-h|--help, Print help\n"
	
return 0
}

safety_check(){
for entry in $(ls $(pwd -P)/draft/$(date +%F).txt); do
	echo $entry
	echo "Writing file to $jpath/$efile ..."
	if [[ ! -d "$(pwd -P)/$jpath" ]]; then
		echo "Creating paths.."
		mkdir -p $(pwd -P)/draft/
		mkdir -p $(pwd -P)/$jpath
		encrypt_journal
	else
		encrypt_journal
	fi
done;
}

randpw(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-64};echo;}

newKey(){
	secret=$(randpw)
	echo "Where should we output the new key? Specify a location or type stdout to output to screen"
	read -p "Enter Absolute Path: " keylocation
	echo "Who is recipient of the key?"
	read recipient
	if [ $keylocation == "stdout" ]; then
		echo $secret | gpg2 -ea -r $recipient -
	else
		echo $secret | gpg2 -ea --batch -o $keylocation -r $recipient -
	fi
}

if [[ $1 == "" || -z $1 ]]; then
    display_help;
    exit;
else
  while getopts "k:hn" options
  do
    case "$options" in
      h) display_help ;;
      k)
        shift
        passwd=`gpg2 -dq --batch "$OPTARG"`
        safety_check
        ;;
      n) newKey ;;
      *)
        display_help
        echo "ERROR: Invalid argument or undefined Key file"
        ;;
    esac
  shift
  done
shift "$(($OPTIND -1))"
fi
