import http from 'k6/http';
import { check, sleep } from 'k6';

// Test con MÚLTIPLES usuarios diferentes
export const options = {
  stages: [
    { duration: '30s', target: 3 },
    { duration: '1m', target: 6 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    checks: ['rate>0.90'],
  },
};

// AGREGA MÁS USUARIOS AQUÍ (emails y passwords reales)
const TEST_USERS = [
  { email: 'americooficial25@gmail.com', password: 'americo123' },
  // { email: 'usuario2@example.com', password: 'password2' },
  // { email: 'usuario3@example.com', password: 'password3' },
  // { email: 'usuario4@example.com', password: 'password4' },
  // { email: 'usuario5@example.com', password: 'password5' },
];

const SUPABASE_URL = 'https://gvdlsypoqstbifdbhafv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZGxzeXBvcXN0YmlmZGJoYWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjUxODcsImV4cCI6MjA3NjUwMTE4N30.JYqNlbGkVSgAuTKhmGCNwsQYGkrk3y0d3z1-gmr91EY';
const AUTH_URL = `${SUPABASE_URL}/auth/v1`;
const BASE_URL = `${SUPABASE_URL}/rest/v1`;

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
  console.log('👥 Test Multi-Usuario');
  console.log(`📊 Usuarios configurados: ${TEST_USERS.length}`);
  console.log(`⏱️  Duración: 2 minutos`);
  return {};
}

function login(email, password) {
  const response = http.post(
    `${AUTH_URL}/token?grant_type=password`,
    JSON.stringify({ email, password }),
    { headers: getHeaders() }
  );

  const success = check(response, {
    '[LOGIN] OK': (r) => r.status === 200,
  });

  if (success) {
    return JSON.parse(response.body);
  }
  return null;
}

function fetchCampaigns(token) {
  const response = http.get(
    `${BASE_URL}/campanias?select=*&limit=5`,
    { headers: getHeaders(token) }
  );

  check(response, {
    '[CAMPAÑAS] OK': (r) => r.status === 200,
  });
}

export default function () {
  // Seleccionar un usuario aleatorio de la lista
  const user = TEST_USERS[Math.floor(Math.random() * TEST_USERS.length)];
  
  console.log(`🔐 Login: ${user.email}`);
  
  const auth = login(user.email, user.password);
  if (!auth) {
    sleep(3);
    return;
  }

  console.log(`✅ ${user.email} autenticado`);
  sleep(2);

  // Ver campañas
  fetchCampaigns(auth.access_token);
  sleep(2);
}

export function teardown() {
  console.log('\n✅ Test completado');
}
