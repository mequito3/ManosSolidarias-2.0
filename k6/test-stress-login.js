import http from 'k6/http';
import { check, sleep } from 'k6';

// Test de STRESS: Muchos logins concurrentes
export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Subir a 5 usuarios
    { duration: '1m', target: 10 },   // Subir a 10 usuarios
    { duration: '1m', target: 20 },   // STRESS: 20 usuarios
    { duration: '30s', target: 10 },  // Bajar a 10
    { duration: '30s', target: 0 },   // Terminar
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    'checks{operation:login}': ['rate>0.95'], // 95% de logins exitosos
  },
};

const TEST_EMAIL = 'americooficial25@gmail.com';
const TEST_PASSWORD = 'americo123';

const SUPABASE_URL = 'https://gvdlsypoqstbifdbhafv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZGxzeXBvcXN0YmlmZGJoYWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjUxODcsImV4cCI6MjA3NjUwMTE4N30.JYqNlbGkVSgAuTKhmGCNwsQYGkrk3y0d3z1-gmr91EY';
const AUTH_URL = `${SUPABASE_URL}/auth/v1`;

function getHeaders() {
  return {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
  };
}

export function setup() {
  console.log('🔥 STRESS TEST - Solo Login');
  console.log(`📧 Usuario: ${TEST_EMAIL}`);
  console.log(`⏱️  Duración: 3.5 minutos`);
  console.log(`👥 Usuarios máximos: 20 concurrentes`);
  console.log('');
  return {};
}

export default function () {
  const payload = JSON.stringify({
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
  });

  const response = http.post(
    `${AUTH_URL}/token?grant_type=password`,
    payload,
    { headers: getHeaders(), tags: { operation: 'login' } }
  );

  const success = check(response, {
    '[LOGIN] status 200': (r) => r.status === 200,
    '[LOGIN] tiene token': (r) => {
      try {
        return JSON.parse(r.body).access_token !== undefined;
      } catch {
        return false;
      }
    },
  }, { operation: 'login' });

  if (success) {
    const body = JSON.parse(response.body);
    console.log(`✅ Login OK - User: ${body.user.id}`);
  } else {
    console.error(`❌ Login falló ${response.status}: ${response.body.substring(0, 100)}`);
  }

  sleep(1 + Math.random() * 2); // Entre 1-3 segundos de delay
}

export function teardown(data) {
  console.log('\n🏁 Stress Test Completado');
  console.log('Revisa las métricas para ver:');
  console.log('- http_reqs: Total de logins realizados');
  console.log('- http_req_duration: Tiempos de respuesta');
  console.log('- checks: Tasa de éxito');
}
