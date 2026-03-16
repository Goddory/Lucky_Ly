import * as adminService from './modules/admin/admin.service.js';

async function testListUsers() {
  try {
    console.log('Testing listUsers with search query...');
    const result = await adminService.listUsers({ 
      search: 'phankhanhnam22@gmail.com',
      limit: 10,
      offset: 0
    });
    console.log('✅ Result:', JSON.stringify(result, null, 2));

    console.log('\nTesting listUsers with empty search...');
    const resultEmpty = await adminService.listUsers({});
    console.log('✅ Result count:', resultEmpty.users.length);

  } catch (err) {
    console.error('❌ Service Error:', err);
  } finally {
    process.exit();
  }
}

testListUsers();
