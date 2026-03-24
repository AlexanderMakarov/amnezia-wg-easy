# wg-password

`wg-password` (wgpw) is a script that generates bcrypt password hashes for use with `wg-easy`, enhancing security by requiring passwords.

## Features

- Generate bcrypt password hashes.
- Easily integrate with `wg-easy` to enforce password requirements.

## Usage on host (native Bun)

To generate a bcrypt password hash, run:

```sh
bun src/wgpw.mjs YOUR_PASSWORD
PASSWORD_HASH='$2b$12$coPqCsPtcFO.Ab99xylBNOW4.Iu7OOA2/ZIboHN6/oyxca3MWo7fW' // literally YOUR_PASSWORD
```

If a password is not provided, the tool will prompt you for one:

```sh
bun src/wgpw.mjs
Enter your password:      // hidden prompt, type in your password
PASSWORD_HASH='$2b$12$coPqCsPtcFO.Ab99xylBNOW4.Iu7OOA2/ZIboHN6/oyxca3MWo7fW'
```

**Important** : make sure to enclose your password in **single quotes** when you run `docker run` command :

```bash
$ echo $2b$12$coPqCsPtcF <-- not correct
b2
$ echo "$2b$12$coPqCsPtcF" <-- not correct
b2
$ echo '$2b$12$coPqCsPtcF' <-- correct
$2b$12$coPqCsPtcF
```

For `.env` files used by systemd, keep the hash exactly as generated.
