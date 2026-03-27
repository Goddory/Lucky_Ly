import fetch from 'node-fetch';

async function testZaloPay() {
  try {
    const username = `test_zalopay_${Date.now()}`;
    // 1. Register to get token
    const regRes = await fetch('http://127.0.0.1:4000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `${username}@test.com`,
        username: username,
        password: "Password123!",
        fullName: "Test ZaloPay"
      })
    });
    const regData = await regRes.json();
    const token = regData.tokens?.accessToken || regData.accessToken;
    
    if (!token) {
        console.error("Register failed:", regData);
        return;
    }

    console.log('Testing ZaloPay Order Creation...');
    const response = await fetch('http://127.0.0.1:4000/api/payment/zalopay/create', {
      method: 'POST',
      headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        amount: 50000,
        orderInfo: 'Test ZaloPay Payment'
      })
    });
    
    const data = await response.json();
    console.log('Status:', response.status);
    console.log('Body:', JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Error:', err);
  }
}

testZaloPay();
