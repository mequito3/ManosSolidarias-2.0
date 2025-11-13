import http from 'k6/http';
import { check, sleep } from 'k6';

// Test controlado: 5 usuarios durante 2 minutos
export const options = {
  stages: [
    { duration: '30s', target: 2 },  // Ramp-up a 2 usuarios
    { duration: '1m', target: 5 },   // Ramp-up a 5 usuarios
    { duration: '30s', target: 0 },  // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.1'],
  },
};

// Usuario de prueba (el mismo que ya funciona)
const TEST_EMAIL = 'americooficial25@gmail.com';
const TEST_PASSWORD = 'americo123';

const SUPABASE_URL = __ENV.SUPABASE_URL || 'https://gvdlsypoqstbifdbhafv.supabase.co';
const SUPABASE_ANON_KEY = __ENV.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZGxzeXBvcXN0YmlmZGJoYWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjUxODcsImV4cCI6MjA3NjUwMTE4N30.JYqNlbGkVSgAuTKhmGCNwsQYGkrk3y0d3z1-gmr91EY';
const BASE_URL = `${SUPABASE_URL}/rest/v1`;
const AUTH_URL = `${SUPABASE_URL}/auth/v1`;

function getHeaders(token = null) {
  const headers = {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
    'Prefer': 'return=representation',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

export function setup() {
  console.log('🚀 Test de Carga - Manos Solidarias');
  console.log(`📍 Supabase: ${SUPABASE_URL}`);
  console.log(`⏱️  Duración: 2 minutos`);
  console.log(`👥 Usuarios máximos: 5`);
  return {};
}

// 1. Login
function login() {
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
    '[LOGIN] status 200': (r) => r.status === 200,
    '[LOGIN] tiene token': (r) => {
      try {
        return JSON.parse(r.body).access_token !== undefined;
      } catch {
        return false;
      }
    },
  });

  if (success) {
    const body = JSON.parse(response.body);
    return {
      token: body.access_token,
      userId: body.user.id,
    };
  }

  // Log del error para debugging
  console.error(`❌ Login error ${response.status}: ${response.body}`);
  return null;
}

// 2. Consultar campañas
function fetchCampaigns(token) {
  const response = http.get(
    `${BASE_URL}/campanias?select=*&estado=eq.activa&order=created_at.desc&limit=10`,
    { headers: getHeaders(token) }
  );

  check(response, {
    '[CAMPAÑAS] status 200': (r) => r.status === 200,
    '[CAMPAÑAS] retorna array': (r) => {
      try {
        return Array.isArray(JSON.parse(r.body));
      } catch {
        return false;
      }
    },
  });

  return response.status === 200;
}

// 3. Consultar perfil
function fetchProfile(token, userId) {
  const response = http.get(
    `${BASE_URL}/profiles?select=*&user_id=eq.${userId}`,
    { headers: getHeaders(token) }
  );

  check(response, {
    '[PERFIL] status 200': (r) => r.status === 200,
    '[PERFIL] tiene datos': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) && body.length > 0;
      } catch {
        return false;
      }
    },
  });

  return response.status === 200;
}

// 4. Crear solicitud (sin imagen)
function createSolicitud(token, userId) {
  const timestamp = Date.now();
  const payload = JSON.stringify({
    titulo: `Test K6 - Solicitud ${timestamp}`,
    descripcion: `Solicitud de prueba creada por K6 load testing. Timestamp: ${new Date().toISOString()}`,
    monto_objetivo: Math.floor(Math.random() * 50000) + 10000,
    fecha_limite: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    categoria: ['Educación', 'Salud', 'Alimentación', 'Vivienda'][Math.floor(Math.random() * 4)],
    user_id: userId,
    estado: 'pendiente',
  });

  const response = http.post(
    `${BASE_URL}/solicitudes`,
    payload,
    { headers: getHeaders(token) }
  );

  const success = check(response, {
    '[SOLICITUD] status 201': (r) => r.status === 201,
    '[SOLICITUD] retorna id': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) && body.length > 0 && body[0].id;
      } catch {
        return false;
      }
    },
  });

  if (success) {
    const body = JSON.parse(response.body);
    return body[0];
  }

  return null;
}

// 5. Consultar solicitudes del usuario
function fetchUserSolicitudes(token, userId) {
  const response = http.get(
    `${BASE_URL}/solicitudes?select=*&user_id=eq.${userId}&order=created_at.desc&limit=5`,
    { headers: getHeaders(token) }
  );

  check(response, {
    '[MIS SOLICITUDES] status 200': (r) => r.status === 200,
  });

  return response.status === 200;
}

// Flujo principal
export default function () {
  // Paso 1: Login
  const auth = login();
  if (!auth) {
    console.error('❌ Login falló, saltando iteración');
    sleep(5);
    return;
  }

  sleep(1);

  // Paso 2: Ver campañas (home)
  fetchCampaigns(auth.token);
  sleep(2);

  // Paso 3: Ver perfil
  fetchProfile(auth.token, auth.userId);
  sleep(2);

  // Paso 4: Crear solicitud (solo 50% de las veces para no saturar)
  if (Math.random() < 0.5) {
    const solicitud = createSolicitud(auth.token, auth.userId);
    if (solicitud) {
      console.log(`✅ Solicitud creada: ${solicitud.id} - "${solicitud.titulo}"`);
    }
    sleep(3);
  }

  // Paso 5: Ver mis solicitudes
  fetchUserSolicitudes(auth.token, auth.userId);
  sleep(2);
}

export function teardown(data) {
  console.log('\n✅ Test de carga completado');
  console.log('Revisa las métricas arriba para ver el rendimiento');
}
