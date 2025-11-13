import http from 'k6/http';
import { check, sleep } from 'k6';

// Quick test configuration - 1 user, 30 seconds
export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<5000'], // More permissive for test
    http_req_failed: ['rate<0.3'],     // Allow more failures for testing
  },
};

const SUPABASE_URL = __ENV.SUPABASE_URL || 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = __ENV.SUPABASE_ANON_KEY || 'your-anon-key';
const BASE_URL = `${SUPABASE_URL}/rest/v1`;
const AUTH_URL = `${SUPABASE_URL}/auth/v1`;

function getHeaders(token = null) {
  const headers = {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

export function setup() {
  console.log('🔍 Quick Connection Test');
  console.log(`📍 Testing: ${SUPABASE_URL}`);
  
  // Test connection with proper headers
  const response = http.get(`${SUPABASE_URL}/rest/v1/`, { headers: getHeaders() });
  if (response.status !== 200 && response.status !== 401) {
    console.error(`❌ Cannot connect to Supabase: ${response.status}`);
    throw new Error('Connection failed');
  }
  
  console.log('✅ Connection successful');
  return {};
}

export default function () {
  // Test 1: Registration
  const timestamp = Date.now();
  const email = `quicktest_${timestamp}@example.com`;
  const password = 'TestPass123!';
  
  console.log(`📝 Testing registration with: ${email}`);
  
  const registerPayload = JSON.stringify({
    email: email,
    password: password,
    options: {
      data: {
        nombre: 'Quick Test',
        apellido: 'User',
      },
    },
  });

  const registerResponse = http.post(
    `${AUTH_URL}/signup`,
    registerPayload,
    { headers: getHeaders() }
  );

  const registerSuccess = check(registerResponse, {
    'registration status is 200': (r) => r.status === 200,
  });

  if (!registerSuccess) {
    console.error(`❌ Registration failed: ${registerResponse.status} - ${registerResponse.body}`);
    return;
  }

  console.log('✅ Registration successful');
  
  const authData = JSON.parse(registerResponse.body);
  const token = authData.session?.access_token;
  
  sleep(1);

  // Test 2: Fetch campaigns
  console.log('📋 Testing campaign fetch...');
  
  const campaignsResponse = http.get(
    `${BASE_URL}/campanias?select=*&limit=5`,
    { headers: getHeaders(token) }
  );

  const campaignsSuccess = check(campaignsResponse, {
    'campaigns fetch status is 200': (r) => r.status === 200,
  });

  if (campaignsSuccess) {
    console.log('✅ Campaign fetch successful');
  } else {
    console.error(`❌ Campaign fetch failed: ${campaignsResponse.status}`);
  }

  sleep(1);

  // Test 3: Create solicitud (without image for speed)
  console.log('📝 Testing solicitud creation...');
  
  const solicitudPayload = JSON.stringify({
    titulo: `Quick Test ${timestamp}`,
    descripcion: 'Quick test solicitud',
    monto_objetivo: 10000,
    fecha_limite: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    categoria: 'Educación',
    user_id: authData.user.id,
    estado: 'pendiente',
  });

  const solicitudResponse = http.post(
    `${BASE_URL}/solicitudes`,
    solicitudPayload,
    { headers: { ...getHeaders(token), 'Prefer': 'return=representation' } }
  );

  const solicitudSuccess = check(solicitudResponse, {
    'solicitud creation status is 201': (r) => r.status === 201,
  });

  if (solicitudSuccess) {
    console.log('✅ Solicitud creation successful');
  } else {
    console.error(`❌ Solicitud creation failed: ${solicitudResponse.status} - ${solicitudResponse.body}`);
  }

  sleep(5); // Longer sleep to avoid rate limits
}

export function teardown(data) {
  console.log('\n✅ Quick test completed');
  console.log('Run the full load test with: k6 run load-test.js');
}
