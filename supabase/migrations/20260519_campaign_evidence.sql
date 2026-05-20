-- =============================================================================
-- Migración: Sistema de evidencias para campañas completadas
-- Fecha: 2026-05-19
-- Resumen:
--   1) Columnas nuevas en `campanias` para tracking de verificación
--   2) Tabla `evidencias_campania` (1 campaña → muchas evidencias)
--   3) Bucket de storage `evidencias-campania`
--   4) Trigger que marca `meta_alcanzada_at` cuando se cumple la meta
--   5) Funciones RPC: marcar campañas vencidas + admin approve/reject
--   6) RLS policies
-- Aplicar idempotente: corre IF NOT EXISTS donde se puede.
-- =============================================================================

-- 1) Columnas nuevas en campanias ---------------------------------------------

alter table public.campanias
  add column if not exists meta_alcanzada_at timestamptz,
  add column if not exists evidence_deadline timestamptz,
  add column if not exists verification_status text
    not null default 'no_aplica'
    check (verification_status in ('no_aplica', 'pendiente_evidencia', 'en_revision', 'verificada', 'sin_verificar')),
  add column if not exists verified_at timestamptz,
  add column if not exists verified_by uuid references auth.users(id) on delete set null,
  add column if not exists rejection_reason text;

-- Índice para consultas frecuentes por estado de verificación
create index if not exists idx_campanias_verification_status
  on public.campanias(verification_status)
  where verification_status <> 'no_aplica';


-- 2) Tabla evidencias_campania -----------------------------------------------

create table if not exists public.evidencias_campania (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id) on delete set null,
  tipo text not null check (tipo in ('foto', 'video', 'pdf', 'otro')),
  url text not null,
  storage_path text,
  filename text,
  mime_type text,
  file_size_bytes bigint,
  description text,
  created_at timestamptz not null default now()
);

create index if not exists idx_evidencias_campania_id
  on public.evidencias_campania(campania_id);

create index if not exists idx_evidencias_uploaded_by
  on public.evidencias_campania(uploaded_by);


-- 3) Storage bucket -----------------------------------------------------------
-- Si ya existe se ignora.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'evidencias-campania',
  'evidencias-campania',
  true,                       -- public read (las evidencias verificadas son visibles para donantes)
  20971520,                   -- 20 MB por archivo
  array[
    'image/jpeg','image/png','image/webp','image/heic','image/heif','image/gif',
    'video/mp4','video/quicktime','video/webm',
    'application/pdf'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;


-- 4) Trigger: marcar meta_alcanzada_at cuando se cumple la meta ---------------

create or replace function public.on_campania_meta_alcanzada()
returns trigger language plpgsql as $$
begin
  -- Si pasa de no-alcanzada a alcanzada, fijamos timestamp + deadline + estado
  if (old.monto_actual < old.monto_objetivo or old.meta_alcanzada_at is null)
     and new.monto_actual >= new.monto_objetivo
     and new.meta_alcanzada_at is null then
    new.meta_alcanzada_at := now();
    new.evidence_deadline := now() + interval '14 days';
    new.verification_status := 'pendiente_evidencia';
  end if;
  return new;
end $$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_campania_meta_alcanzada') then
    create trigger trg_campania_meta_alcanzada
      before update on public.campanias
      for each row execute function public.on_campania_meta_alcanzada();
  end if;
end $$;


-- 5) Funciones RPC -----------------------------------------------------------

-- 5.1) Marcar como "sin_verificar" las campañas cuyo plazo venció sin evidencia aprobada.
-- Se ejecuta vía Supabase cron o invocada manualmente desde el admin.
create or replace function public.mark_overdue_evidences()
returns int language plpgsql security definer as $$
declare
  affected int;
begin
  update public.campanias
     set verification_status = 'sin_verificar'
   where verification_status in ('pendiente_evidencia', 'en_revision')
     and evidence_deadline is not null
     and evidence_deadline < now();
  get diagnostics affected = row_count;
  return affected;
end $$;

-- 5.2) Admin aprueba la verificación de una campaña.
create or replace function public.admin_verify_campania(
  p_campania_id uuid,
  p_admin_id uuid
)
returns void language plpgsql security definer as $$
begin
  if not public.is_admin(p_admin_id) then
    raise exception 'No autorizado: solo administradores pueden verificar campañas.';
  end if;

  update public.campanias
     set verification_status = 'verificada',
         verified_at = now(),
         verified_by = p_admin_id,
         rejection_reason = null
   where id = p_campania_id
     and verification_status in ('pendiente_evidencia','en_revision','sin_verificar');
end $$;

-- 5.3) Admin rechaza y pide más evidencia.
create or replace function public.admin_reject_campania_evidence(
  p_campania_id uuid,
  p_admin_id uuid,
  p_reason text
)
returns void language plpgsql security definer as $$
begin
  if not public.is_admin(p_admin_id) then
    raise exception 'No autorizado: solo administradores pueden rechazar evidencias.';
  end if;

  update public.campanias
     set verification_status = 'pendiente_evidencia',
         rejection_reason = p_reason,
         verified_at = null,
         verified_by = null
   where id = p_campania_id;
end $$;

-- 5.4) Cuando se sube una evidencia, mover a "en_revision" si estaba pendiente.
create or replace function public.on_evidencia_inserted()
returns trigger language plpgsql as $$
begin
  update public.campanias
     set verification_status = 'en_revision'
   where id = new.campania_id
     and verification_status = 'pendiente_evidencia';
  return new;
end $$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_evidencia_inserted') then
    create trigger trg_evidencia_inserted
      after insert on public.evidencias_campania
      for each row execute function public.on_evidencia_inserted();
  end if;
end $$;


-- 6) Row Level Security ------------------------------------------------------

alter table public.evidencias_campania enable row level security;

drop policy if exists evidencias_public_read on public.evidencias_campania;
drop policy if exists evidencias_owner_select on public.evidencias_campania;
drop policy if exists evidencias_owner_insert on public.evidencias_campania;
drop policy if exists evidencias_owner_delete on public.evidencias_campania;
drop policy if exists evidencias_admin_full on public.evidencias_campania;

-- Cualquiera puede leer las evidencias (son parte del registro público de transparencia).
create policy evidencias_public_read on public.evidencias_campania
for select
to anon, authenticated
using (true);

-- El creador de la campaña puede subir evidencias.
create policy evidencias_owner_insert on public.evidencias_campania
for insert
to authenticated
with check (
  exists (
    select 1 from public.campanias c
    where c.id = campania_id
      and c.creador_id = auth.uid()
  )
);

-- El creador puede borrar sus propias evidencias mientras esté pendiente.
create policy evidencias_owner_delete on public.evidencias_campania
for delete
to authenticated
using (
  uploaded_by = auth.uid()
  and exists (
    select 1 from public.campanias c
    where c.id = campania_id
      and c.verification_status in ('pendiente_evidencia','en_revision')
  )
);

-- Admin full access.
create policy evidencias_admin_full on public.evidencias_campania
for all
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));


-- 7) Storage policies para el bucket evidencias-campania ---------------------

-- Lectura pública.
drop policy if exists "evidencias_storage_public_read" on storage.objects;
create policy "evidencias_storage_public_read" on storage.objects
for select
to anon, authenticated
using (bucket_id = 'evidencias-campania');

-- Inserción: solo el creador de la campaña referenciada en la ruta puede subir.
-- Convención de ruta: evidencias-campania/{campania_id}/{archivo}
drop policy if exists "evidencias_storage_owner_insert" on storage.objects;
create policy "evidencias_storage_owner_insert" on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'evidencias-campania'
  and exists (
    select 1 from public.campanias c
    where c.id::text = (storage.foldername(name))[1]
      and c.creador_id = auth.uid()
  )
);

-- Borrado: dueño puede borrar archivos de sus campañas.
drop policy if exists "evidencias_storage_owner_delete" on storage.objects;
create policy "evidencias_storage_owner_delete" on storage.objects
for delete
to authenticated
using (
  bucket_id = 'evidencias-campania'
  and exists (
    select 1 from public.campanias c
    where c.id::text = (storage.foldername(name))[1]
      and c.creador_id = auth.uid()
  )
);

-- Admin storage full access.
drop policy if exists "evidencias_storage_admin_full" on storage.objects;
create policy "evidencias_storage_admin_full" on storage.objects
for all
to authenticated
using (
  bucket_id = 'evidencias-campania'
  and public.is_admin(auth.uid())
)
with check (
  bucket_id = 'evidencias-campania'
  and public.is_admin(auth.uid())
);


-- 8) Backfill ----------------------------------------------------------------
-- Para campañas ya completadas antes de esta migración:
-- - Si ya alcanzaron la meta, fijamos meta_alcanzada_at = updated_at como aproximación
-- - Las marcamos como 'sin_verificar' (no podemos saber si tenían evidencia)
update public.campanias
   set meta_alcanzada_at = coalesce(meta_alcanzada_at, updated_at),
       evidence_deadline = coalesce(evidence_deadline, updated_at + interval '14 days'),
       verification_status = case
         when verification_status = 'no_aplica' then 'sin_verificar'
         else verification_status
       end
 where monto_actual >= monto_objetivo
   and verification_status = 'no_aplica';
