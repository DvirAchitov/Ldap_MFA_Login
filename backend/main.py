from flask import Flask, request, jsonify
from flask_cors import CORS
from ldap3 import Server, Connection, ALL, SUBTREE
import pyotp
import os

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # Enable CORS for all origins

# LDAP Configuration
LDAP_HOST = os.getenv('LDAP_HOST', 'ldap')
LDAP_PORT = int(os.getenv('LDAP_PORT', 389))
LDAP_BASE_DN = os.getenv('LDAP_BASE_DN', 'dc=example,dc=org')
LDAP_ADMIN_DN = f"cn=admin,{LDAP_BASE_DN}"
LDAP_ADMIN_PASSWORD = "admin"

def get_ldap_connection():
    """Create an LDAP connection for admin operations"""
    server = Server(f'ldap://{LDAP_HOST}:{LDAP_PORT}', get_info=ALL)
    conn = Connection(server, LDAP_ADMIN_DN, LDAP_ADMIN_PASSWORD, auto_bind=True)
    return conn

def authenticate_user(username, password):
    """Authenticate user against LDAP"""
    try:
        print(f"Attempting to authenticate user: {username}")
        # First, find the user's DN
        conn = get_ldap_connection()
        search_filter = f'(uid={username})'
        print(f"Searching LDAP with filter: {search_filter}")
        conn.search(
            search_base=LDAP_BASE_DN,
            search_filter=search_filter,
            search_scope=SUBTREE,
            attributes=['description']
        )
        
        if not conn.entries:
            print(f"User {username} not found in LDAP")
            return False, None
        
        user_dn = conn.entries[0].entry_dn
        print(f"Found user DN: {user_dn}")
        mfa_secret = str(conn.entries[0].description) if 'description' in conn.entries[0] else None
        conn.unbind()
        
        # Try to bind with user credentials
        server = Server(f'ldap://{LDAP_HOST}:{LDAP_PORT}', get_info=ALL)
        user_conn = Connection(server, user_dn, password)
        
        print(f"Attempting to bind as {user_dn}")
        if user_conn.bind():
            print(f"Successfully authenticated user: {username}")
            user_conn.unbind()
            return True, mfa_secret
        else:
            print(f"Failed to bind as {user_dn}: {user_conn.result}")
            return False, None
            
    except Exception as e:
        print(f"LDAP authentication error: {e}")
        import traceback
        traceback.print_exc()
        return False, None

@app.route('/auth/login', methods=['POST'])
def login():
    """Handle login with username and password"""
    data = request.get_json()
    
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'error': 'Username and password required'}), 400
    
    username = data['username']
    password = data['password']
    
    # Authenticate against LDAP
    authenticated, mfa_secret = authenticate_user(username, password)
    
    if authenticated:
        # Password is correct, now require MFA
        return jsonify({
            'mfa_required': True,
            'message': 'Password correct. Please provide MFA code.'
        }), 200
    else:
        return jsonify({'error': 'Invalid username or password'}), 401

@app.route('/auth/mfa-verify', methods=['POST'])
def mfa_verify():
    """Verify MFA TOTP code"""
    data = request.get_json()
    
    if not data or 'username' not in data or 'mfa_code' not in data:
        return jsonify({'error': 'Username and MFA code required'}), 400
    
    username = data['username']
    mfa_code = data['mfa_code']
    
    try:
        # Get user's MFA secret from LDAP
        conn = get_ldap_connection()
        search_filter = f'(uid={username})'
        conn.search(
            search_base=LDAP_BASE_DN,
            search_filter=search_filter,
            search_scope=SUBTREE,
            attributes=['description']
        )
        
        if not conn.entries or 'description' not in conn.entries[0]:
            return jsonify({'error': 'MFA not configured for this user'}), 400
        
        mfa_secret = str(conn.entries[0].description)
        conn.unbind()
        
        # Verify TOTP code
        totp = pyotp.TOTP(mfa_secret)
        if totp.verify(mfa_code, valid_window=1):
            return jsonify({
                'success': True,
                'message': 'MFA verification successful'
            }), 200
        else:
            return jsonify({'error': 'Invalid MFA code'}), 401
            
    except Exception as e:
        print(f"MFA verification error: {e}")
        return jsonify({'error': 'MFA verification failed'}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

