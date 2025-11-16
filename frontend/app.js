// Backend API URL - automatically use the same host as frontend
const API_URL = `${window.location.protocol}//${window.location.hostname}:5000`;

// DOM Elements
const loginSection = document.getElementById('login-section');
const mfaSection = document.getElementById('mfa-section');
const successSection = document.getElementById('success-section');
const messageDiv = document.getElementById('message');

const usernameInput = document.getElementById('username');
const passwordInput = document.getElementById('password');
const loginBtn = document.getElementById('login-btn');

const mfaCodeInput = document.getElementById('mfa-code');
const mfaBtn = document.getElementById('mfa-btn');

let currentUsername = '';

// Show message helper
function showMessage(text, type = 'info') {
    messageDiv.textContent = text;
    messageDiv.className = `message ${type}`;
    messageDiv.classList.remove('hidden');
}

// Hide message helper
function hideMessage() {
    messageDiv.classList.add('hidden');
}

// Login button click handler
loginBtn.addEventListener('click', async () => {
    const username = usernameInput.value.trim();
    const password = passwordInput.value;

    if (!username || !password) {
        showMessage('Please enter both username and password', 'error');
        return;
    }

    loginBtn.disabled = true;
    showMessage('Authenticating...', 'info');

    try {
        const response = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, password }),
        });

        const data = await response.json();

        if (response.ok && data.mfa_required) {
            currentUsername = username;
            showMessage('Password correct! Please enter your MFA code.', 'success');
            
            // Hide login section and show MFA section
            loginSection.classList.add('hidden');
            mfaSection.classList.remove('hidden');
            mfaCodeInput.focus();
        } else {
            showMessage(data.error || 'Login failed. Please check your credentials.', 'error');
            loginBtn.disabled = false;
        }
    } catch (error) {
        showMessage('Connection error. Please make sure the backend is running.', 'error');
        loginBtn.disabled = false;
        console.error('Login error:', error);
    }
});

// MFA button click handler
mfaBtn.addEventListener('click', async () => {
    const mfaCode = mfaCodeInput.value.trim();

    if (!mfaCode || mfaCode.length !== 6 || !/^\d{6}$/.test(mfaCode)) {
        showMessage('Please enter a valid 6-digit code', 'error');
        return;
    }

    mfaBtn.disabled = true;
    showMessage('Verifying MFA code...', 'info');

    try {
        const response = await fetch(`${API_URL}/auth/mfa-verify`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                username: currentUsername,
                mfa_code: mfaCode,
            }),
        });

        const data = await response.json();

        if (response.ok && data.success) {
            showMessage('MFA verification successful!', 'success');
            
            // Show success section
            setTimeout(() => {
                hideMessage();
                mfaSection.classList.add('hidden');
                successSection.classList.remove('hidden');
            }, 1000);
        } else {
            showMessage(data.error || 'Invalid MFA code. Please try again.', 'error');
            mfaBtn.disabled = false;
            mfaCodeInput.value = '';
            mfaCodeInput.focus();
        }
    } catch (error) {
        showMessage('Connection error. Please try again.', 'error');
        mfaBtn.disabled = false;
        console.error('MFA verification error:', error);
    }
});

// Allow Enter key to submit forms
usernameInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') passwordInput.focus();
});

passwordInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') loginBtn.click();
});

mfaCodeInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') mfaBtn.click();
});

