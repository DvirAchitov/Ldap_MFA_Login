# Add User Script

A bash script to add users to LDAP with automatic MFA setup.

## Usage

```bash
# Make it executable
chmod +x ldap/add_user.sh

# Add a new user
./ldap/add_user.sh -user jsmith -name "John Smith" -password mypassword123 -mail john.smith@example.com
```

## Output

The script will:
1. ✅ Generate a random MFA secret
2. ✅ Assign the next available UID number
3. ✅ Create the user in LDAP
4. ✅ Display the MFA secret and QR code URL

Example output:
```
============================================================
LDAP User Creation Tool
============================================================

[1/4] Generated MFA secret: ABCD1234EFGH5678IJKL9012
[2/4] Assigned UID number: 10001
[3/4] Created LDIF entry for user: jsmith
[4/4] Adding user to LDAP...

✅ SUCCESS! User added to LDAP successfully!

============================================================
USER CREDENTIALS
============================================================
Username: jsmith
Password: mypassword123
Email:    john.smith@example.com

============================================================
MFA SETUP INSTRUCTIONS
============================================================

MFA Secret: ABCD1234EFGH5678IJKL9012

Option 1 - Scan QR Code:
Visit this URL to see the QR code:
https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=...

Option 2 - Manual Entry in Google Authenticator:
1. Open Google Authenticator app
2. Tap '+' to add account
3. Choose 'Enter a setup key'
4. Account name: jsmith
5. Key: ABCD1234EFGH5678IJKL9012
6. Time-based: Yes

Option 3 - Generate TOTP code via command:
python3 -c "import pyotp; print(pyotp.TOTP('ABCD1234EFGH5678IJKL9012').now())"

============================================================
User can now login at: http://your-server:8080
============================================================
```

## Requirements

- Docker and docker-compose running
- LDAP container must be named `q2-ldap-1` (or edit the script to match your container name)

## Examples

```bash
# Add user Alice
./ldap/add_user.sh -user alice -name "Alice Wonder" -password alice123 -mail alice@example.com

# Add user Bob
./ldap/add_user.sh -user bob -name "Bob Builder" -password bob456 -mail bob@example.com

# Add user with complex name
./ldap/add_user.sh -user "jvd" -name "Jean-Claude Van Damme" -password jcvd789 -mail jcvd@example.com
```

## Troubleshooting

**Error: "docker: command not found"**
- Make sure Docker is installed and in your PATH
- Try running with sudo if needed

**Error: "cannot connect to LDAP"**
- Make sure the LDAP container is running: `docker compose ps`
- Check container name: `docker ps | grep ldap`
- If different name, edit the script and change `q2-ldap-1` to your container name

**Error: "User already exists"**
- Choose a different username
- Or delete the existing user first

