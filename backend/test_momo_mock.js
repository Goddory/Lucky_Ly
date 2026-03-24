import fetch from 'node-fetch'; // Wait, node 24 has fetch, but I'll use native fetch

async function testMock() {
  try {
    console.log('Testing MoMo Mock Flow...');
    
    // Simulate register to get token (if needed, but for simplicity I'll skip auth if possible or mock it)
    // Actually, createPaymentUrl requires authenticateToken.
    // I'll use a hack to bypass auth for this test or just use the controller's logic directly.
    
    const response = await fetch('http://localhost:4000/api/payment/momo/create', {
      method: 'POST',
      headers: { 
          'Content-Type': 'application/json',
          'Authorization': 'Bearer MOCK_TOKEN' // This might fail if the middleware is strict
      },
      body: JSON.stringify({
        amount: 50000,
        orderInfo: 'Test Mock'
      })
    });
    
    const text = await response.text();
    console.log('Status:', response.status);
    console.log('Body:', text);
  } catch (err) {
    console.error('Error:', err);
  }
}

testMock();
