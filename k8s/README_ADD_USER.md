# Add User Script (Kubernetes)

A bash script to add users to LDAP with automatic MFA setup in your Kubernetes deployment.

## Usage

```bash
# Make it executable
chmod +x k8s/add_user.sh

# Add a new user
./k8s/add_user.sh -user jsmith -name "John Smith" -password mypassword123 -mail john.smith@example.com
```

## Output

The script will:
1. ✅ Find the LDAP pod automatically
2. ✅ Generate a random MFA secret
3. ✅ Assign the next available UID number
4. ✅ Create the user in LDAP
5. ✅ Display the MFA secret and QR code URL

Example output:
```
============================================================
LDAP User Creation Tool (Kubernetes)
============================================================

Using LDAP pod: ldap-9cb9c7c9d-55nkh

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

- kubectl configured and connected to your cluster
- LDAP pod running (deployed via k8s/deploy.sh)

## Examples

```bash
# Add user Alice
./k8s/add_user.sh -user alice -name "Alice Wonder" -password alice123 -mail alice@example.com

# Add user Bob
./k8s/add_user.sh -user bob -name "Bob Builder" -password bob456 -mail bob@example.com

# Add user with complex name
./k8s/add_user.sh -user jvd -name "Jean-Claude Van Damme" -password jcvd789 -mail jcvd@example.com
```

## Troubleshooting

**Error: "LDAP pod not found"**
- Make sure LDAP is running: `kubectl get pods -l app=ldap`
- If not running, deploy it: `./k8s/deploy.sh`

**Error: "ldapadd: Invalid credentials"**
- Check LDAP admin password in `k8s/ldap.yaml`
- Default is `admin` / `admin`

**Error: "User already exists"**
- Choose a different username
- Or delete the existing user first

## Delete a User

To delete a user from LDAP:

```bash
LDAP_POD=$(kubectl get pods -l app=ldap -o jsonpath='{.items[0].metadata.name}')
kubectl exec $LDAP_POD -- ldapdelete -x -H ldap://localhost \
  -D "cn=admin,dc=example,dc=org" -w admin \
  "uid=USERNAME,ou=people,dc=example,dc=org"
```

Replace `USERNAME` with the actual username.

