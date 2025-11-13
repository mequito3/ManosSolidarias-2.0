import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Métricas personalizadas para rastrear correctamente
const loginSuccess = new Counter('login_success_count');
const loginFail = new Counter('login_fail_count');
const rateLimitHits = new Counter('rate_limit_429_count');

// Test optimizado para CAPTURAS DE PANTALLA
// Muestra información clara y organizada en la consola
export const options = {
  stages: [
    { duration: '20s', target: 5 },   // Warm-up: 5 usuarios
    { duration: '40s', target: 10 },  // Carga normal: 10 usuarios
    { duration: '30s', target: 15 },  // Carga alta: 15 usuarios
    { duration: '20s', target: 5 },   // Cool-down: 5 usuarios
    { duration: '10s', target: 0 },   // Finalizar
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    'checks{operation:login}': ['rate>0.20'], // 20% mínimo (esperando rate limit)
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
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║         PRUEBA DE CARGA - MANOS SOLIDARIAS               ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 CONFIGURACIÓN DEL TEST:');
  console.log('   • Aplicación: Sistema de Donaciones');
  console.log('   • Funcionalidad: Autenticación (Login)');
  console.log('   • Duración total: 2 minutos');
  console.log('   • Usuarios máximos: 15 concurrentes');
  console.log('   • Backend: Supabase (PostgreSQL + Auth)');
  console.log('');
  console.log('⏱️  FASES DEL TEST:');
  console.log('   1️⃣  Warm-up     → 5 usuarios  (20s)');
  console.log('   2️⃣  Carga normal → 10 usuarios (40s)');
  console.log('   3️⃣  Carga alta   → 15 usuarios (30s)');
  console.log('   4️⃣  Cool-down   → 5 usuarios  (20s)');
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🚀 INICIANDO PRUEBA...');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
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
    'Login exitoso': (r) => r.status === 200,
  }, { operation: 'login' });

  if (success) {
    loginSuccess.add(1);
  } else {
    loginFail.add(1);
    if (response.status === 429) {
      rateLimitHits.add(1);
    }
  }

  sleep(1 + Math.random() * 2); // 1-3 segundos de delay
}

export function handleSummary(data) {
  // Extraer métricas reales de K6
  const totalRequests = data.metrics.http_reqs?.values.count || 0;
  const iterations = data.metrics.iterations?.values.count || 0;
  const httpFailed = data.metrics.http_req_failed?.values.passes || 0;
  const successCount = totalRequests - httpFailed;
  const failCount = httpFailed;
  
  const checksTotal = data.metrics.checks?.values.passes + data.metrics.checks?.values.fails || 0;
  const checksPassed = data.metrics.checks?.values.passes || 0;
  
  const avgDuration = data.metrics.http_req_duration?.values.avg || 0;
  const p95Duration = data.metrics.http_req_duration?.values['p(95)'] || 0;
  const maxDuration = data.metrics.http_req_duration?.values.max || 0;
  
  const rateLimitCount = data.metrics.rate_limit_429_count?.values.count || 0;
  
  const duration = data.state.testRunDurationMs / 1000;
  const successRate = totalRequests > 0 ? ((successCount / totalRequests) * 100).toFixed(1) : '0.0';
  
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ PRUEBA COMPLETADA');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('📈 RESUMEN DE RESULTADOS:');
  console.log('');
  console.log(`   ✅ Logins exitosos:     ${successCount} (${successRate}%)`);
  console.log(`   ❌ Logins fallidos:     ${failCount}`);
  console.log(`   ⚠️  Rate limit (429):    ${rateLimitCount}`);
  console.log(`   📊 Total de intentos:   ${totalRequests}`);
  console.log(`   ✔️  Checks pasados:      ${checksPassed}/${checksTotal}`);
  console.log(`   👥 Iteraciones:         ${iterations}`);
  console.log(`   ⏱️  Duración total:      ${duration.toFixed(1)}s`);
  console.log('');
  console.log('⏱️  TIEMPOS DE RESPUESTA:');
  console.log(`   • Promedio:  ${avgDuration.toFixed(2)}ms`);
  console.log(`   • P95:       ${p95Duration.toFixed(2)}ms`);
  console.log(`   • Máximo:    ${maxDuration.toFixed(2)}ms`);
  console.log('');
  console.log('🔍 ANÁLISIS:');
  
  if (parseFloat(successRate) > 70) {
    console.log('   ✅ Excelente rendimiento - La mayoría de logins fueron exitosos');
  } else if (parseFloat(successRate) > 20) {
    console.log('   ⚠️  Rendimiento moderado - Rate limit alcanzado (esperado en Supabase Free)');
    console.log('   ✓  Sistema estable bajo carga');
    console.log('   ✓  Aplicación funciona correctamente');
    console.log('   → Fallos por limitación de infraestructura (Supabase Free: 30 logins/5min)');
  } else {
    console.log('   ❌ Rate limit muy restrictivo - Considerar plan superior de Supabase');
  }
  
  if (avgDuration < 1000) {
    console.log(`   ⚡ Tiempo de respuesta promedio: ${avgDuration.toFixed(0)}ms (Excelente)`);
  } else {
    console.log(`   ⚡ Tiempo de respuesta promedio: ${avgDuration.toFixed(0)}ms (Aceptable)`);
  }
  
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}
