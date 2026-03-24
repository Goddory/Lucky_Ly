import fetch from 'node-fetch';

async function testMock() {
  try {
    const username = `test_momo_${Date.now()}`;
    const regRes = await fetch('http://127.0.0.1:4000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `${username}@test.com`,
        username: username,
        password: "Password123!",
        fullName: "Test MoMo"
      })
    });
    const regData = await regRes.json();
    const token = regData.tokens?.accessToken || regData.accessToken;
    
    if (!token) {
        console.error("Register failed:", regData);
        return;
    }

    console.log('Testing MoMo Mock Flow...');
    const response = await fetch('http://127.0.0.1:4000/api/payment/momo/create', {
      method: 'POST',
      headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        amount: 50000,
        orderInfo: 'Test Mock Payment'
      })
    });
    
    const data = await response.json();
    console.log('Status:', response.status);
    console.log('Body:', JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Error:', err);
  }
}

testMock();
