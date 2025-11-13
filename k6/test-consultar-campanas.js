import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Métricas personalizadas
const querySuccess = new Counter('query_success_count');
const queryFail = new Counter('query_fail_count');

// Test optimizado para CAPTURAS DE PANTALLA - Consultar Campañas
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
    'checks{operation:query_campaigns}': ['rate>0.95'], // 95% de éxito esperado
  },
};

const TEST_EMAIL = 'americooficial25@gmail.com';
const TEST_PASSWORD = 'americo123';

const SUPABASE_URL = 'https://gvdlsypoqstbifdbhafv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZGxzeXBvcXN0YmlmZGJoYWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjUxODcsImV4cCI6MjA3NjUwMTE4N30.JYqNlbGkVSgAuTKhmGCNwsQYGkrk3y0d3z1-gmr91EY';
const AUTH_URL = `${SUPABASE_URL}/auth/v1`;
const REST_URL = `${SUPABASE_URL}/rest/v1`;

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

  if (response.status === 200) {
    try {
      const body = JSON.parse(response.body);
      return body.access_token;
    } catch (e) {
      return null;
    }
  }
  
  return null;
}

export function setup() {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║    PRUEBA DE CARGA - CONSULTA DE CAMPAÑAS                ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('📊 CONFIGURACIÓN DEL TEST:');
  console.log('   • Aplicación: Sistema de Donaciones');
  console.log('   • Funcionalidad: Consultar Campañas Activas');
  console.log('   • Duración total: 2 minutos');
  console.log('   • Usuarios máximos: 15 concurrentes');
  console.log('   • Backend: Supabase (PostgreSQL + REST API)');
  console.log('');
  console.log('🎯 OBJETIVO DEL TEST:');
  console.log('   • Medir rendimiento de consultas a base de datos');
  console.log('   • Evaluar comportamiento bajo carga concurrente');
  console.log('   • Verificar tiempos de respuesta del sistema');
  console.log('   • Demostrar escalabilidad de la aplicación');
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
  // 1. Login para obtener token
  const token = login();
  
  if (!token) {
    sleep(1);
    return;
  }
  
  // 2. Consultar campañas activas
  const response = http.get(
    `${REST_URL}/campanias?select=*&estado=eq.activa&order=created_at.desc&limit=20`,
    { 
      headers: getHeaders(token),
      tags: { operation: 'query_campaigns' }
    }
  );

  const success = check(response, {
    'Consulta exitosa': (r) => r.status === 200,
    'Respuesta válida': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body);
      } catch {
        return false;
      }
    },
  }, { operation: 'query_campaigns' });

  if (success) {
    querySuccess.add(1);
  } else {
    queryFail.add(1);
  }

  sleep(1 + Math.random() * 1.5); // 1-2.5 segundos de delay
}

export function handleSummary(data) {
  // Extraer métricas reales de K6
  const totalRequests = data.metrics.http_reqs?.values.count || 0;
  const iterations = data.metrics.iterations?.values.count || 0;
  const httpFailed = data.metrics.http_req_failed?.values.passes || 0;
  
  // Calcular requests de login vs queries (2 requests por iteración exitosa)
  const loginRequests = iterations;
  const queryRequests = totalRequests - loginRequests;
  const successCount = queryRequests - httpFailed;
  const failCount = httpFailed;
  
  const checksTotal = data.metrics.checks?.values.passes + data.metrics.checks?.values.fails || 0;
  const checksPassed = data.metrics.checks?.values.passes || 0;
  
  const avgDuration = data.metrics.http_req_duration?.values.avg || 0;
  const p95Duration = data.metrics.http_req_duration?.values['p(95)'] || 0;
  const p99Duration = data.metrics.http_req_duration?.values['p(99)'] || 0;
  const minDuration = data.metrics.http_req_duration?.values.min || 0;
  const maxDuration = data.metrics.http_req_duration?.values.max || 0;
  
  const duration = data.state.testRunDurationMs / 1000;
  const successRate = queryRequests > 0 ? ((successCount / queryRequests) * 100).toFixed(1) : '0.0';
  const throughput = (iterations / duration).toFixed(2);
  
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ PRUEBA COMPLETADA');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('📈 RESUMEN DE RESULTADOS:');
  console.log('');
  console.log(`   ✅ Consultas exitosas:    ${successCount} (${successRate}%)`);
  console.log(`   ❌ Consultas fallidas:    ${failCount}`);
  console.log(`   📊 Total de consultas:    ${queryRequests}`);
  console.log(`   🔐 Logins realizados:     ${loginRequests}`);
  console.log(`   ✔️  Checks pasados:        ${checksPassed}/${checksTotal}`);
  console.log(`   👥 Iteraciones totales:   ${iterations}`);
  console.log(`   📡 Total HTTP requests:   ${totalRequests}`);
  console.log(`   ⚡ Throughput:            ${throughput} req/s`);
  console.log(`   ⏱️  Duración total:        ${duration.toFixed(1)}s`);
  console.log('');
  console.log('⏱️  TIEMPOS DE RESPUESTA:');
  console.log(`   • Mínimo:    ${minDuration.toFixed(2)}ms`);
  console.log(`   • Promedio:  ${avgDuration.toFixed(2)}ms`);
  console.log(`   • P95:       ${p95Duration.toFixed(2)}ms`);
  console.log(`   • P99:       ${p99Duration.toFixed(2)}ms`);
  console.log(`   • Máximo:    ${maxDuration.toFixed(2)}ms`);
  console.log('');
  console.log('🔍 ANÁLISIS Y CONCLUSIONES:');
  console.log('');
  
  if (parseFloat(successRate) > 95) {
    console.log('   ✅ EXCELENTE RENDIMIENTO');
    console.log('   ✓  Sistema altamente confiable (>95% éxito)');
    console.log('   ✓  Maneja carga concurrente eficientemente');
    console.log('   ✓  Base de datos responde correctamente');
    console.log('');
    console.log('   💡 CONCLUSIÓN PARA TESIS:');
    console.log('      "El sistema mantiene alta disponibilidad (>95%) bajo');
    console.log('       carga de 15 usuarios concurrentes, con tiempos de');
    console.log(`       respuesta óptimos (P95: ${p95Duration.toFixed(0)}ms), demostrando`);
    console.log('       escalabilidad adecuada para el caso de uso."');
  } else if (parseFloat(successRate) > 80) {
    console.log('   ⚠️  BUEN RENDIMIENTO con margen de mejora');
    console.log('   ✓  Sistema funciona bajo carga');
    console.log('   ⚠️  Algunos requests fallaron (revisar logs)');
  } else {
    console.log('   ❌ Rendimiento por debajo de lo esperado');
    console.log('   ⚠️  Revisar configuración de base de datos');
    console.log('   ⚠️  Posibles limitaciones de infraestructura');
  }
  
  console.log('');
  
  if (avgDuration < 500) {
    console.log(`   ⚡ Tiempo de respuesta: ${avgDuration.toFixed(0)}ms (EXCELENTE)`);
    console.log('      → Sistema muy rápido, experiencia de usuario óptima');
  } else if (avgDuration < 1000) {
    console.log(`   ⚡ Tiempo de respuesta: ${avgDuration.toFixed(0)}ms (BUENO)`);
    console.log('      → Cumple estándares de rendimiento web');
  } else if (avgDuration < 2000) {
    console.log(`   ⚡ Tiempo de respuesta: ${avgDuration.toFixed(0)}ms (ACEPTABLE)`);
    console.log('      → Dentro de límites aceptables');
  } else {
    console.log(`   ⚠️  Tiempo de respuesta: ${avgDuration.toFixed(0)}ms (MEJORAR)`);
    console.log('      → Considerar optimización de queries');
  }
  
  console.log('');
  console.log('📊 MÉTRICAS CLAVE PARA DOCUMENTACIÓN:');
  console.log(`   • Disponibilidad: ${successRate}%`);
  console.log(`   • Latencia P95: ${p95Duration.toFixed(0)}ms`);
  console.log(`   • Throughput: ${throughput} requests/segundo`);
  console.log(`   • Usuarios concurrentes: 15 (máximo)`);
  console.log(`   • Total de operaciones: ${iterations}`);
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}
