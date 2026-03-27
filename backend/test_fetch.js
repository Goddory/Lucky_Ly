import fetch from 'node-fetch';

async function testApi() {
  try {
    const username = `user${Math.floor(Date.now() / 1000)}`;
    const regRes = await fetch('http://127.0.0.1:4000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `${username}@example.com`,
        username: username,
        password: "Password123!",
        fullName: "Test User"
      })
    });
    const regData = await regRes.json();
    console.log("Register:", regData);
    
    // The previous script probably extracted regData.accessToken which was undefined, it's actually in regData.tokens.accessToken
    const token = regData.tokens?.accessToken || regData.accessToken;
    
    if (token) {
        console.log("Using Token:", token.substring(0, 10) + "...");
        const vnpRes = await fetch('http://127.0.0.1:4000/api/payment/vnpay/create', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            amount: 50000,
            orderInfo: "Nap tien Lucky Ly"
          })
        });
        
        const text = await vnpRes.text();
        console.log("VNPay Status:", vnpRes.status);
        console.log("VNPay Body:", text);
    } else {
        console.log("No token found in response");
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

testApi();
