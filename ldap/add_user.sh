#!/bin/bash
# Script to add a new user to OpenLDAP with MFA support
# Usage: ./add_user.sh -user USERNAME -name "Full Name" -password PASSWORD -mail EMAIL

set -e

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -user)
            USERNAME="$2"
            shift 2
            ;;
        -name)
            FULLNAME="$2"
            shift 2
            ;;
        -password)
            PASSWORD="$2"
            shift 2
            ;;
        -mail)
            EMAIL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 -user USERNAME -name \"Full Name\" -password PASSWORD -mail EMAIL"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$USERNAME" || -z "$FULLNAME" || -z "$PASSWORD" || -z "$EMAIL" ]]; then
    echo "Error: All arguments are required!"
    echo "Usage: $0 -user USERNAME -name \"Full Name\" -password PASSWORD -mail EMAIL"
    exit 1
fi

echo "============================================================"
echo "LDAP User Creation Tool"
echo "============================================================"

# Generate random MFA secret (32 characters, base32)
MFA_SECRET=$(head /dev/urandom | tr -dc A-Z2-7 | head -c 32)
echo ""
echo "[1/4] Generated MFA secret: $MFA_SECRET"

# Get next available UID number
NEXT_UID=$(docker exec q2-ldap-1 ldapsearch -x -H ldap://localhost \
    -b "ou=people,dc=example,dc=org" -D "cn=admin,dc=example,dc=org" -w admin \
    "uidNumber" 2>/dev/null | grep "uidNumber:" | awk '{print $2}' | sort -n | tail -1)

if [[ -z "$NEXT_UID" ]]; then
    NEXT_UID=10000
else
    NEXT_UID=$((NEXT_UID + 1))
fi
echo "[2/4] Assigned UID number: $NEXT_UID"

# Split full name into first and last name
GIVEN_NAME=$(echo "$FULLNAME" | awk '{print $1}')
SURNAME=$(echo "$FULLNAME" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | xargs)
if [[ -z "$SURNAME" ]]; then
    SURNAME="$GIVEN_NAME"
fi

# Create LDIF content
LDIF_CONTENT="dn: uid=$USERNAME,ou=people,dc=example,dc=org
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $USERNAME
cn: $FULLNAME
sn: $SURNAME
givenName: $GIVEN_NAME
mail: $EMAIL
userPassword: $PASSWORD
uidNumber: $NEXT_UID
gidNumber: $NEXT_UID
homeDirectory: /home/$USERNAME
loginShell: /bin/bash
description: $MFA_SECRET
"

echo "[3/4] Created LDIF entry for user: $USERNAME"
echo "[4/4] Adding user to LDAP..."

# Add user to LDAP
echo "$LDIF_CONTENT" | docker exec -i q2-ldap-1 ldapadd -x \
    -H ldap://localhost -D "cn=admin,dc=example,dc=org" -w admin

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ SUCCESS! User added to LDAP successfully!"
    echo ""
    echo "============================================================"
    echo "USER CREDENTIALS"
    echo "============================================================"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "Email:    $EMAIL"
    echo ""
    echo "============================================================"
    echo "MFA SETUP INSTRUCTIONS"
    echo "============================================================"
    echo ""
    echo "MFA Secret: $MFA_SECRET"
    echo ""
    echo "Option 1 - Scan QR Code:"
    echo "Visit this URL to see the QR code:"
    QR_URI="otpauth://totp/Login%20System:$USERNAME?secret=$MFA_SECRET&issuer=Login%20System"
    echo "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$QR_URI"
    echo ""
    echo "Option 2 - Manual Entry in Google Authenticator:"
    echo "1. Open Google Authenticator app"
    echo "2. Tap '+' to add account"
    echo "3. Choose 'Enter a setup key'"
    echo "4. Account name: $USERNAME"
    echo "5. Key: $MFA_SECRET"
    echo "6. Time-based: Yes"
    echo ""
    echo "Option 3 - Generate TOTP code via command:"
    echo "python3 -c \"import pyotp; print(pyotp.TOTP('$MFA_SECRET').now())\""
    echo ""
    echo "============================================================"
    echo "User can now login at: http://your-server:8080"
    echo "============================================================"
    echo ""
else
    echo ""
    echo "❌ ERROR! Failed to add user to LDAP"
    exit 1
fi

