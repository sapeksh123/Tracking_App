// Test admin login
const testLogin = async () => {
  try {
    const response = await fetch('http://localhost:5000/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'admin',
        password: 'admin'
      })
    });
    
    const data = await response.json();
    console.log('Status:', response.status);
    console.log('Response:', JSON.stringify(data, null, 2));
    
    if (response.ok) {
      console.log('\n✓ Login successful!');
      console.log('Token:', data.token);
    } else {
      console.log('\n✗ Login failed!');
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
};

testLogin();
