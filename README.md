# JournalGPG
This project was born out of the need for an encrypted journal that is able to be stored locally and provide plausible denaiblity for the encryption key. Many online platforms, such as [Penzu](https://penzu.com), [Journey](journey.cloud), [Goodnight Journal](https://www.goodnightjournal.com/), [journalate](https://myjournalate.com/) might provide the same functions but there is no guarentee that the entries you write won't be see by others as it is merely a suponea away from being captured or released reguardless if it the contents are said to be encrypted when using these platforms. 

If you read the terms and conditions, on some platforms you don't own the data and they are allowed to use it as they see fit. This does not bode well when the entires you're writing are meant to be your intermost private thoughts and feelings. Knowning this may also prevent you from expressing yourself in a healthier way and in a more freely fashion. 

In the creation of this project the goal is to provide a journal which is able to surivive the rapid changing of technology by storing the entires as plain text, to provide a journal which is local to your computer and encrypted using an offline key to provide better security. 

This code is primarly bash shell scripting, I thought about writing it in python but I'm more familar with bash scripts and I also wanted to further the goal of not needing much in the way of special software to use this script. Anyone should be able to stand up a very basic and limited linux system and begin writing in a journal using only a text editor and making use of bash and GnuPG.

## Installation
1. Download the script to your system
`sudo curl -fsSL -o /usr/local/bin/encrypt-draft https://raw.githubusercontent.com/caseyrichins/JournalGPG/master/encrypt-draft.sh`
2. Set the permissions on the script
`chmod 644 /usr/local/bin/encrypt-draft`

## Some Warnings and disclaimers
* When creating a new entry the draft file is not encrypted, so it is recommended that your journal live on an encrypted disk or encrypted container. This can be accomplished with luks or veracrypt depending on your needs and requirements. 
* The security of your journal depends soley on the strength of your GnuPG key and your personal operational security requirements. 4096 bit RSA is recommended. If you're wanting to have your GnuPG key stored seperatly from your computer check out [drduh](https://github.com/drduh) [YubiKey-Guide](https://github.com/drduh/YubiKey-Guide). Exporting GnuPG key to an external YubiKey.
* The entries you encrypt are protected with a random symmetric key that is generated and protected by your gpg key, the script uses they random key to encrypt the individual entires with AES-256 encryption and SHA-512 digests.

## Usage
* When using for the first time you'll want to generate a symmetric key that will be used to encrypt the entires, this symmetric key is protected by your private gnuPG key. The resulting generated key that is encrypted is a 64 character ascii string that looks something like this:

<pre>=<Koa2Rrer.kj"^Ul;+Xbq;HtNu5lU7A}`EiH,5T93|qd+k2.T*K;oAWr"4[U4Rb</pre>.

```encrypt-draft newkey
Where should we output the new key? Specify a location or type stdout to output to screen                                                                                                         [INFO]
Enter Absolute Path: stdout
Who is recipient of the key? <recipient>@gmail.com
-----BEGIN PGP MESSAGE-----

hQIMAwAAAAAAAAAAAQ/+IYRyimk72g+1OfU3kO3tdfZl/uSBSJ41+PR8zoaAm0vf
D17tJHlOkGh9GvXLSjwOL8acBhQIBnVsZCsikMIhy3Er4i+6cRvkmNqOJLSTBSE7
VC8AIwcMvtGbTPh534HWPOkNhKURJCquAzWQySoo7MpyGv9m9LSQBsZQGuasZy/o
EUw3U9kUhqNHZW048ZUW9WUb4bHLXvd8k1XJAnc6THX4EVAuvuBwakPU72ctxkWo
0KbA1v/zObT3g0k7x7XHihC+2vULOpnPYMqzJogh9L4uSa4HSAL20ffUWBwnZgeV
XXlFCYrb4NLNVspxTGklGZ/XYbqBh0i3SDxmoT1V3mBjbLwdu66AkdBegddiYLTV
f++wlfrXZKZCa3iecvE7gvFFJL1miFdhJjU/54BXN7/VNVwVvLi+nb83lo5glykJ
HlffaYeXd5/IrHrjUqYa8zcxkN7w+lG1fhu5vviNeKfOsvr9VzN+Cp5yerKlzFWw
fEOHrEg1TnBVavE7MYPNfQ6ls03bBJWgvC85qOMOQwRluxvqHZcXO0VlZ8kjv09f
Dx7+BXFlJDJYA6lamzUuwD9qDzos4NFB9bm8zHw8Tzfxi5MMvotKhPMci0xuw/Bb
KptF0GWp1as4fMOLWG4CJZD+LKkjpv7VSvJOQ/QcSWT9zd8XXNg0xB4EZ3d6oCrS
fAG1SIs5juVfM/A2euJ6UidBwx4uSgyMng2A4T7eTcdYsvOOnYTOREnGuPGGw/2C
4QhxyfiWTytozlqu9zqCuPaSYrCaft1/h/MMek1geUBsUCsXe5LCNo0eoefJiZu9
T6oIy9C/E4IzCFWYMd/9jJyWBn6hFoySAcGd1jk=
=NUPy
-----END PGP MESSAGE-----
```
Choose stdout if you don't want save your key to local file, otherwise provide the absolute path of where you want the key stored. You might even consider storing on a onion webserver or other personal web server using stdout option. Another option would be to burn the resulting file to a cd for immutability or copy to a usb drive to have the key remain sepereate from your computer. 

* A new draft file for the current day by issuing `newdraft` command option. Make sure you're in the location where your journal will live, be that a local or external disk. 

`encrypt-draft newdraft`

* Encryption of your draft file once written is accomplished with the encrypt fuction and the passing of required options. Once the encryption has completed successfully the draft is erased.

`encrypt-draft encrypt --keyfile /path/to/key.asc`

If your key is stored on a personal webserver you may use the `--key-from-url` option, likewise if have Tor installed and your key is stored on a onion website add the `--proxy` option to command string.

If your commands are being executed from outside your journal directory you must pass the `--config-path` option to specify the location your journal files.

* Decryption of a entry to retrieve your memory or review your thoughts is simple and is accomplished via the `decrypt` function. For security the decrypted entry is only ever output to stdout or your screen and is never decrypted to a stored file.

`encrypt-draft decrypt --keyfile /path/to/key.asc --entry 2021/February/Feb_04.asc`

If your key is stored on a personal webserver you may use the `--key-from-url` option, likewise if have Tor installed and your key is stored on a onion website add the `--proxy` option to command string.

If your commands are being executed from outside your journal directory you must pass the `--config-path` option to specify the location your journal files.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[Unlicensed](https://choosealicense.com/licenses/unlicense/)
* Currently subject to change during alpha developlment, first stable release may change or secure this license.
