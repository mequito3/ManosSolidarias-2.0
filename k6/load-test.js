import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const authDuration = new Trend('auth_duration');
const campaignCreationDuration = new Trend('campaign_creation_duration');
const organizationCreationDuration = new Trend('organization_creation_duration');
const kermesseCreationDuration = new Trend('kermesse_creation_duration');
const uploadDuration = new Trend('upload_duration');
const requestCounter = new Counter('requests_total');

// Configuration - IMPORTANT: Set your Supabase URL and anon key here
const SUPABASE_URL = __ENV.SUPABASE_URL || 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = __ENV.SUPABASE_ANON_KEY || 'your-anon-key';
const BASE_URL = `${SUPABASE_URL}/rest/v1`;
const AUTH_URL = `${SUPABASE_URL}/auth/v1`;
const STORAGE_URL = `${SUPABASE_URL}/storage/v1`;

// Test image URL (using a placeholder service)
const TEST_IMAGE_URL = 'https://picsum.photos/800/600';

// Load test configuration
export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Ramp up to 5 users
    { duration: '1m', target: 10 },   // Ramp up to 10 users
    { duration: '2m', target: 10 },   // Stay at 10 users
    { duration: '30s', target: 20 },  // Spike to 20 users
    { duration: '1m', target: 20 },   // Stay at spike
    { duration: '30s', target: 5 },   // Ramp down to 5
    { duration: '30s', target: 0 },   // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests should be below 2s
    http_req_failed: ['rate<0.05'],     // Less than 5% of requests should fail
    errors: ['rate<0.1'],               // Less than 10% error rate
    auth_duration: ['p(95)<3000'],      // Auth should complete in <3s
    campaign_creation_duration: ['p(95)<5000'], // Campaign creation <5s
  },
};

// Helper function to get headers
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

// Generate unique test data
function generateTestUser() {
  const timestamp = Date.now();
  const randomId = Math.floor(Math.random() * 100000);
  return {
    email: `test_user_${timestamp}_${randomId}@example.com`,
    password: 'TestPassword123!',
    nombre: `Usuario Test ${randomId}`,
    apellido: `Apellido ${randomId}`,
    telefono: `555${String(randomId).padStart(7, '0')}`,
  };
}

// 1. User Registration
function registerUser(userData) {
  const startTime = Date.now();
  
  const payload = JSON.stringify({
    email: userData.email,
    password: userData.password,
    options: {
      data: {
        nombre: userData.nombre,
        apellido: userData.apellido,
        telefono: userData.telefono,
      },
    },
  });

  const response = http.post(
    `${AUTH_URL}/signup`,
    payload,
    { headers: getHeaders() }
  );

  requestCounter.add(1);
  authDuration.add(Date.now() - startTime);

  const success = check(response, {
    'registration status is 200': (r) => r.status === 200,
    'registration returns user': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.user && body.user.email === userData.email;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  if (success) {
    const body = JSON.parse(response.body);
    return {
      userId: body.user.id,
      accessToken: body.session?.access_token,
      refreshToken: body.session?.refresh_token,
    };
  }

  console.error(`Registration failed: ${response.status} - ${response.body}`);
  return null;
}

// 2. User Login
function loginUser(email, password) {
  const startTime = Date.now();
  
  const payload = JSON.stringify({
    email: email,
    password: password,
  });

  const response = http.post(
    `${AUTH_URL}/token?grant_type=password`,
    payload,
    { headers: getHeaders() }
  );

  requestCounter.add(1);
  authDuration.add(Date.now() - startTime);

  const success = check(response, {
    'login status is 200': (r) => r.status === 200,
    'login returns access token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.access_token !== undefined;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  if (success) {
    const body = JSON.parse(response.body);
    return {
      accessToken: body.access_token,
      refreshToken: body.refresh_token,
      userId: body.user.id,
    };
  }

  console.error(`Login failed: ${response.status} - ${response.body}`);
  return null;
}

// 3. Download test image (simulate file preparation)
function downloadTestImage() {
  const response = http.get(TEST_IMAGE_URL);
  
  const success = check(response, {
    'image download status is 200': (r) => r.status === 200,
    'image has content': (r) => r.body.length > 0,
  });

  if (success) {
    return response.body;
  }

  return null;
}

// 4. Upload cover image to Supabase Storage
function uploadCoverImage(token, userId, imageData) {
  const startTime = Date.now();
  const fileName = `cover_${Date.now()}_${Math.floor(Math.random() * 10000)}.jpg`;
  const storagePath = `users/${userId}/solicitudes/covers/${fileName}`;

  const response = http.post(
    `${STORAGE_URL}/object/documentos/${storagePath}`,
    imageData,
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'apikey': SUPABASE_ANON_KEY,
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
      },
    }
  );

  requestCounter.add(1);
  uploadDuration.add(Date.now() - startTime);

  const success = check(response, {
    'image upload status is 200 or 201': (r) => r.status === 200 || r.status === 201,
  });

  errorRate.add(!success);

  if (success) {
    return `${SUPABASE_URL}/storage/v1/object/public/documentos/${storagePath}`;
  }

  console.error(`Image upload failed: ${response.status} - ${response.body}`);
  return null;
}

// 5. Create Solicitud (Campaign Request)
function createSolicitud(token, userId, coverImageUrl) {
  const startTime = Date.now();
  
  const payload = JSON.stringify({
    titulo: `Campaña de Prueba ${Date.now()}`,
    descripcion: `Esta es una campaña de prueba creada durante el test de carga. ` +
                 `Timestamp: ${new Date().toISOString()}. ` +
                 `El objetivo es recaudar fondos para una causa importante.`,
    monto_objetivo: Math.floor(Math.random() * 50000) + 10000, // Between 10k and 60k
    fecha_limite: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 30 days from now
    imagen_portada: coverImageUrl,
    categoria: ['Educación', 'Salud', 'Alimentación', 'Vivienda'][Math.floor(Math.random() * 4)],
    user_id: userId,
    estado: 'pendiente',
  });

  const response = http.post(
    `${BASE_URL}/solicitudes`,
    payload,
    { headers: getHeaders(token) }
  );

  requestCounter.add(1);
  campaignCreationDuration.add(Date.now() - startTime);

  const success = check(response, {
    'solicitud creation status is 201': (r) => r.status === 201,
    'solicitud returns id': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) && body.length > 0 && body[0].id;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  if (success) {
    const body = JSON.parse(response.body);
    return body[0];
  }

  console.error(`Solicitud creation failed: ${response.status} - ${response.body}`);
  return null;
}

// 6. Create Organization
function createOrganization(token, userId) {
  const startTime = Date.now();
  const orgName = `Organización Test ${Date.now()}`;
  
  const payload = JSON.stringify({
    nombre: orgName,
    descripcion: `Organización creada durante test de carga. Esta es una organización ` +
                 `dedicada a realizar actividades solidarias en la comunidad.`,
    direccion: `Calle Falsa ${Math.floor(Math.random() * 1000)}, Ciudad Test`,
    telefono: `555${String(Math.floor(Math.random() * 10000000)).padStart(7, '0')}`,
    email: `${orgName.toLowerCase().replace(/\s+/g, '_')}@test.org`,
    tipo_organizacion: ['ONG', 'Fundación', 'Asociación Civil'][Math.floor(Math.random() * 3)],
    user_id: userId,
    estado: 'activa',
  });

  const response = http.post(
    `${BASE_URL}/organizaciones`,
    payload,
    { headers: getHeaders(token) }
  );

  requestCounter.add(1);
  organizationCreationDuration.add(Date.now() - startTime);

  const success = check(response, {
    'organization creation status is 201': (r) => r.status === 201,
    'organization returns id': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) && body.length > 0 && body[0].id;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  if (success) {
    const body = JSON.parse(response.body);
    return body[0];
  }

  console.error(`Organization creation failed: ${response.status} - ${response.body}`);
  return null;
}

// 7. Create Kermesse
function createKermesse(token, userId, organizacionId) {
  const startTime = Date.now();
  const kermesseName = `Kermesse Test ${Date.now()}`;
  
  // Generate random coordinates (Bolivia - approximate range)
  const latitude = -17.0 + (Math.random() * 2 - 1); // Around La Paz area
  const longitude = -65.0 + (Math.random() * 2 - 1);
  
  const payload = JSON.stringify({
    nombre: kermesseName,
    descripcion: `Kermesse creada durante test de carga. Evento solidario con diversas ` +
                 `actividades para recaudar fondos para la comunidad.`,
    fecha_inicio: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days from now
    fecha_fin: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000).toISOString(), // 8 days from now
    ubicacion: `Plaza Test ${Math.floor(Math.random() * 100)}`,
    latitud: latitude,
    longitud: longitude,
    organizacion_id: organizacionId,
    user_id: userId,
    estado: 'planificada',
  });

  const response = http.post(
    `${BASE_URL}/kermesses`,
    payload,
    { headers: getHeaders(token) }
  );

  requestCounter.add(1);
  kermesseCreationDuration.add(Date.now() - startTime);

  const success = check(response, {
    'kermesse creation status is 201': (r) => r.status === 201,
    'kermesse returns id': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) && body.length > 0 && body[0].id;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  if (success) {
    const body = JSON.parse(response.body);
    return body[0];
  }

  console.error(`Kermesse creation failed: ${response.status} - ${response.body}`);
  return null;
}

// 8. Fetch Campaigns (Home Screen)
function fetchCampaigns(token) {
  const response = http.get(
    `${BASE_URL}/campanias?select=*&estado=eq.activa&order=created_at.desc&limit=20`,
    { headers: getHeaders(token) }
  );

  requestCounter.add(1);

  const success = check(response, {
    'campaigns fetch status is 200': (r) => r.status === 200,
    'campaigns returns array': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body);
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);
  return success;
}

// 9. Fetch User Profile
function fetchUserProfile(token, userId) {
  const response = http.get(
    `${BASE_URL}/profiles?select=*&user_id=eq.${userId}`,
    { headers: getHeaders(token) }
  );

  requestCounter.add(1);

  const success = check(response, {
    'profile fetch status is 200': (r) => r.status === 200,
    'profile returns data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) && body.length > 0;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);
  return success;
}

// Main test scenario
export default function () {
  const scenario = Math.random();
  
  // 70% of users do the full flow
  if (scenario < 0.7) {
    group('Full User Flow', function () {
      // Generate user data
      const userData = generateTestUser();
      
      // 1. Register
      group('Registration', function () {
        const authData = registerUser(userData);
        if (!authData || !authData.accessToken) {
          console.error('Registration failed, skipping rest of flow');
          return;
        }
        sleep(1);

        // Store auth data for subsequent requests
        userData.token = authData.accessToken;
        userData.userId = authData.userId;
      });

      sleep(2); // Simulate user thinking time

      // 2. Login (even though we have token from registration, test the login flow)
      group('Login', function () {
        const loginData = loginUser(userData.email, userData.password);
        if (loginData && loginData.accessToken) {
          userData.token = loginData.accessToken;
        }
      });

      sleep(2);

      // 3. View campaigns (home screen)
      group('View Campaigns', function () {
        fetchCampaigns(userData.token);
      });

      sleep(1);

      // 4. Create solicitud with image
      group('Create Campaign', function () {
        // Download test image
        const imageData = downloadTestImage();
        if (!imageData) {
          console.error('Failed to download test image');
          return;
        }
        sleep(1);

        // Upload cover image
        const coverUrl = uploadCoverImage(userData.token, userData.userId, imageData);
        if (!coverUrl) {
          console.error('Failed to upload cover image');
          return;
        }
        sleep(1);

        // Create solicitud
        const solicitud = createSolicitud(userData.token, userData.userId, coverUrl);
        if (solicitud) {
          console.log(`✅ Solicitud created: ${solicitud.id}`);
        }
      });

      sleep(3);

      // 5. Create organization
      group('Create Organization', function () {
        const organization = createOrganization(userData.token, userData.userId);
        if (organization) {
          console.log(`✅ Organization created: ${organization.id}`);
          
          sleep(2);
          
          // 6. Create kermesse for this organization
          group('Create Kermesse', function () {
            const kermesse = createKermesse(userData.token, userData.userId, organization.id);
            if (kermesse) {
              console.log(`✅ Kermesse created: ${kermesse.id}`);
            }
          });
        }
      });

      sleep(2);

      // 7. View profile
      group('View Profile', function () {
        fetchUserProfile(userData.token, userData.userId);
      });
    });
  } 
  // 20% of users only browse (read-only)
  else if (scenario < 0.9) {
    group('Browse Only Flow', function () {
      const userData = generateTestUser();
      
      // Register to get a token
      const authData = registerUser(userData);
      if (!authData || !authData.accessToken) {
        return;
      }

      sleep(1);

      // Browse campaigns
      fetchCampaigns(authData.accessToken);
      sleep(3);

      // View profile
      fetchUserProfile(authData.accessToken, authData.userId);
    });
  }
  // 10% of users only register
  else {
    group('Registration Only Flow', function () {
      const userData = generateTestUser();
      registerUser(userData);
    });
  }

  sleep(1); // Cool down between iterations
}

// Setup function (runs once at the beginning)
export function setup() {
  console.log('🚀 Starting Manos Solidarias Load Test');
  console.log(`📍 Supabase URL: ${SUPABASE_URL}`);
  console.log(`📊 Test configuration: ${JSON.stringify(options.stages)}`);
  
  // Verify connection with proper headers
  const response = http.get(`${SUPABASE_URL}/rest/v1/`, { headers: getHeaders() });
  if (response.status !== 200 && response.status !== 401) {
    console.error(`❌ Failed to connect to Supabase: ${response.status}`);
    throw new Error('Cannot connect to Supabase');
  }
  
  console.log('✅ Connected to Supabase successfully');
  return {};
}

// Teardown function (runs once at the end)
export function teardown(data) {
  console.log('🏁 Load test completed');
  console.log(`📈 Total requests: ${requestCounter.value}`);
}
