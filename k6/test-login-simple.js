import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuración: Solo 1 usuario, 10 segundos
export const options = {
  vus: 1,
  iterations: 3, // Solo 3 intentos de login
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.1'],
  },
};

// IMPORTANTE: Cambia estos valores por un usuario REAL que ya existe en tu app
const TEST_EMAIL = 'americooficial25@gmail.com';  // <-- CAMBIAR AQUÍ
const TEST_PASSWORD = 'americo123';         // <-- CAMBIAR AQUÍ

const SUPABASE_URL = __ENV.SUPABASE_URL || 'https://gvdlsypoqstbifdbhafv.supabase.co';
const SUPABASE_ANON_KEY = __ENV.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZGxzeXBvcXN0YmlmZGJoYWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjUxODcsImV4cCI6MjA3NjUwMTE4N30.JYqNlbGkVSgAuTKhmGCNwsQYGkrk3y0d3z1-gmr91EY';
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
  console.log('🔐 Test de Login Simple');
  console.log(`📧 Email: ${TEST_EMAIL}`);
  console.log(`🔑 Supabase: ${SUPABASE_URL}`);
  return {};
}

export default function () {
  console.log(`\n🔄 Intento de login...`);
  
  const payload = JSON.stringify({
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
  });

  const response = http.post(
    `${AUTH_URL}/token?grant_type=password`,
    payload,
    { headers: getHeaders() }
  );

  const success = check(response, {
    'login status es 200': (r) => r.status === 200,
    'retorna access token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.access_token !== undefined;
      } catch {
        return false;
      }
    },
    'retorna user': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.user && body.user.email === TEST_EMAIL;
      } catch {
        return false;
      }
    },
  });

  if (success) {
    const body = JSON.parse(response.body);
    console.log(`✅ Login exitoso!`);
    console.log(`   User ID: ${body.user.id}`);
    console.log(`   Email: ${body.user.email}`);
    console.log(`   Token: ${body.access_token.substring(0, 20)}...`);
  } else {
    console.error(`❌ Login falló: ${response.status}`);
    console.error(`   Respuesta: ${response.body}`);
  }

  sleep(2); // Esperar 2 segundos entre intentos
}

export function teardown(data) {
  console.log('\n✅ Test de login completado');
  console.log('Si funcionó, puedes probar el test completo con: k6 run load-test.js');
}
