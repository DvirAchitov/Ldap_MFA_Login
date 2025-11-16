# Simple Login System with HTML + Backend + OpenLDAP

A complete authentication system with MFA support using Docker Compose.

**(SYSTEM_EXPLANATION_HE.md)**

## Architecture

This system consists of three Docker containers:

1. **Frontend** (port 8080) - HTML login page with JavaScript
2. **Backend** (port 5000) - Python Flask API for authentication
3. **LDAP** (port 389) - OpenLDAP server for user storage

## File Structure

```
project/
├── docker-compose.yml
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   └── app.js
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── main.py
└── ldap/
    └── bootstrap.ldif
```

## Quick Start

1. **Start the system:**
   ```bash
   docker compose up -d --build
   ```

2. **Access the login page:**
   Open your browser to: http://localhost:8080

3. **Use test credentials:**
   - Username: `dahituv`, Password: `password123`

## MFA Setup

### For Development/Testing:

Each user has a pre-configured MFA secret. To get the current TOTP code:

**Use Google Authenticator app**
1. Open Google Authenticator on your phone
2. Add account manually

## 🔄 Login Flow

1. **Step 1**: Enter username and password → Click "Login"
2. **Step 2**: If credentials are correct, MFA input appears
3. **Step 3**: Enter 6-digit TOTP code → Click "Verify MFA"
4. **Step 4**: Success! You're logged in

## 🛠️ API Endpoints

### POST /auth/login
Authenticates username and password via LDAP.

**Request:**
```json
{
  "username": "dahituv",
  "password": "password123"
}
```

**Response:**
```json
{
  "mfa_required": true,
  "message": "Password correct. Please provide MFA code."
}
```

### POST /auth/mfa-verify
Verifies the TOTP MFA code.

**Request:**
```json
{
  "username": "dahituv",
  "mfa_code": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "MFA verification successful"
}
```

## Testing

1. **Check if containers are running:**
   ```bash
   docker compose ps
   ```

2. **View logs:**
   ```bash
   docker compose logs -f
   ```
   
## 🛑 Stop the System

```bash
docker compose down
```

## 📝 Adding New Users

Edit `ldap/bootstrap.ldif` and add a new user entry:

```ldif
dn: uid=newuser,ou=people,dc=example,dc=org
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: newuser
cn: New User
sn: User
givenName: New
mail: new.user@example.org
userPassword: newpassword
uidNumber: 10003
gidNumber: 10003
homeDirectory: /home/newuser
loginShell: /bin/bash
mfaSecret: YOUR_TOTP_SECRET_HERE
```

Alternatively, there's a script `ldap/add_user.sh` that automates adding users (it generates a TOTP secret, assigns the next UID, creates the LDIF entry and pushes the user into the running LDAP container). See `ldap/README_ADD_USER.md` for full usage and examples.

Quick example:

```bash
chmod +x ldap/add_user.sh
./ldap/add_user.sh -user jsmith -name "John Smith" -password mypassword123 -mail john.smith@example.com
```

Generate a new TOTP secret with Python (requires the `pyotp` package):
```bash
pip install pyotp
python -c "import pyotp; print(pyotp.random_base32())"
```

Then rebuild:
```bash
docker compose down
docker compose up -d --build
```

## 🔍 Troubleshooting

**Frontend can't connect to backend:**
- Make sure all containers are running: `docker compose ps`
- Check backend logs: `docker compose logs backend`
- Verify CORS is enabled in backend

**LDAP connection fails:**
- Check LDAP container is running: `docker compose logs ldap`
- Verify bootstrap.ldif syntax
- Wait 10-15 seconds after startup for LDAP to initialize

**MFA code always fails:**
- Check system time is synchronized
- Verify the TOTP secret is correct
- TOTP codes are valid for 30 seconds

## 🎯 Features

✅ Username/password authentication via LDAP  
✅ TOTP-based MFA (Google Authenticator compatible)  
✅ Modern, responsive UI  
✅ Docker Compose for easy deployment
✅ Pre-configured test users  

## 🔧 Technology Stack

- **Frontend**: HTML, CSS, JavaScript (Vanilla)
- **Backend**: Python Flask
- **LDAP**: OpenLDAP (osixia/openldap)
- **MFA**: TOTP (pyotp library)
- **Container**: Docker & Docker Compose

## 📚 Additional Resources

- [LDAP3 Documentation](https://ldap3.readthedocs.io/)
- [PyOTP Documentation](https://pyotp.readthedocs.io/)
- [Flask Documentation](https://flask.palletsprojects.com/)
