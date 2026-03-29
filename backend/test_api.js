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
    
    const token = regData.tokens?.accessToken || regData.accessToken;
    
    if (token) {
        console.log("Using Token:", token.substring(0, 10) + "...");
        const evtRes = await fetch('http://127.0.0.1:4000/api/events', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            title: "Test Event",
            note: "Testing note",
            date: new Date().toISOString(),
            type: "personal_note"
          })
        });
        
        console.log("Create Event Status:", evtRes.status);
        console.log("Create Event Body:", await evtRes.text());

        const listRes = await fetch('http://127.0.0.1:4000/api/events', {
            method: 'GET',
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });
        console.log("List Events Status:", listRes.status);
        console.log("List Events Body:", await listRes.text());
    } else {
        console.log("No token found in response");
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

testApi();
