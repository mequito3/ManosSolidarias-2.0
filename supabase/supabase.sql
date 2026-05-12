-- ============================================================
-- 0) EXTENSIONES
-- ============================================================
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists btree_gin;

-- ============================================================
-- 1) FUNCIONES AUXILIARES
-- ============================================================
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create or replace function public.gen_slug(t text)
returns text language plpgsql as $$
declare s text;
begin
  s := lower(regexp_replace(coalesce(t,''), '[^a-zA-Z0-9]+', '-', 'g'));
  s := regexp_replace(s, '(^-|-$)', '', 'g');
  if s = '' then s := encode(gen_random_bytes(4),'hex'); end if;
  return s;
end $$;

-- ============================================================
-- 2) IDENTIDAD Y ORGANIZACIONES
-- ============================================================
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  bio text,
  telefono text,
  ciudad text,
  direccion text,
  website text,
  instagram text,
  facebook text,
  twitter text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_profiles_touch') then
    create trigger trg_profiles_touch before update on public.profiles
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'documento_tipo'
  ) then
    alter table public.profiles add column documento_tipo text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'documento_numero'
  ) then
    alter table public.profiles add column documento_numero text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'perfil_completo'
  ) then
    alter table public.profiles add column perfil_completo boolean not null default false;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'banco_titular'
  ) then
    alter table public.profiles add column banco_titular text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'banco_nombre'
  ) then
    alter table public.profiles add column banco_nombre text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'banco_tipo_cuenta'
  ) then
    alter table public.profiles add column banco_tipo_cuenta text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'banco_numero_cuenta'
  ) then
    alter table public.profiles add column banco_numero_cuenta text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'donacion_qr_url'
  ) then
    alter table public.profiles add column donacion_qr_url text;
  end if;
end $$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb;
  full_name text;
begin
  meta := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  full_name := coalesce(
    meta->>'display_name',
    meta->>'full_name',
    meta->>'name',
    meta->>'user_name',
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Miembro Solidario'
  );

  insert into public.profiles (user_id, display_name, avatar_url)
  values (new.id, full_name, meta->>'avatar_url')
  on conflict (user_id) do update
    set display_name = coalesce(excluded.display_name, public.profiles.display_name),
        avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);

  return new;
end;
$$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_handle_new_auth_user') then
    create trigger trg_handle_new_auth_user
    after insert on auth.users
    for each row execute function public.handle_new_auth_user();
  end if;
end $$;

create or replace function public.is_admin(uid uuid)
returns boolean language sql stable as $$
  select coalesce((select p.is_admin from public.profiles p where p.user_id=uid), false);
$$;

do $$
begin
  begin
    execute 'drop policy if exists profiles_select_self_or_admin on public.profiles';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists profiles_public_read on public.profiles';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists profiles_upsert_self_or_admin on public.profiles';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists profiles_update_self_or_admin on public.profiles';
  exception when others then null;
  end;
end $$;

create policy profiles_public_read on public.profiles
for select
to anon, authenticated
using (true);

create policy profiles_upsert_self_or_admin on public.profiles
for insert
to authenticated
with check (auth.uid() = user_id or public.is_admin(auth.uid()));

create policy profiles_update_self_or_admin on public.profiles
for update
to authenticated
using (auth.uid() = user_id or public.is_admin(auth.uid()))
with check (auth.uid() = user_id or public.is_admin(auth.uid()));

do $$
begin
  update public.profiles p
  set display_name = coalesce(
    u.raw_user_meta_data->>'display_name',
    u.raw_user_meta_data->>'full_name',
    u.raw_user_meta_data->>'name',
    u.raw_user_meta_data->>'user_name',
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'Miembro Solidario'
  )
  from auth.users u
  where u.id = p.user_id
    and (p.display_name is null or p.display_name ilike '%@%');
end $$;

create table if not exists public.organizaciones (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  tipo text,
  descripcion text,
  telefono text,
  email text,
  sitio_web text,
  direccion text,
  logo_url text,
  estado text not null default 'pendiente' check (estado in ('pendiente','aprobada','rechazada')),
  notas_admin text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_org_touch') then
    create trigger trg_org_touch before update on public.organizaciones
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  begin
    execute 'drop policy if exists organizaciones_public_read on public.organizaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists organizaciones_owner_read on public.organizaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists organizaciones_owner_insert on public.organizaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists organizaciones_admin_full_access on public.organizaciones';
  exception when others then null;
  end;
end $$;

create policy organizaciones_public_read on public.organizaciones
for select
to anon,authenticated
using (estado = 'aprobada');

create policy organizaciones_owner_read on public.organizaciones
for select
to authenticated
using (owner_id = auth.uid());

create policy organizaciones_owner_insert on public.organizaciones
for insert
to authenticated
with check (owner_id = auth.uid() and estado = 'pendiente');

create policy organizaciones_admin_full_access on public.organizaciones
for all
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

create or replace function public.on_organizacion_estado_change()
returns trigger
language plpgsql
as $$
declare
  v_message text;
  v_payload jsonb;
begin
  if TG_OP <> 'UPDATE' then
    return NEW;
  end if;

  if NEW.estado = OLD.estado then
    return NEW;
  end if;

  if NEW.owner_id is null then
    return NEW;
  end if;

  v_payload := jsonb_build_object(
    'organizacion_id', NEW.id,
    'nombre', NEW.nombre
  );

  if NEW.estado = 'aprobada' then
    v_message := 'Tu organización quedó verificada y ahora es visible para los donantes.';

    insert into public.notificaciones(user_id, tipo, mensaje, payload)
    values (NEW.owner_id, 'organizacion_aprobada', v_message, v_payload);

  elsif NEW.estado = 'rechazada' then
    if NEW.notas_admin is not null and btrim(NEW.notas_admin) <> '' then
      v_payload := v_payload || jsonb_build_object('motivo', NEW.notas_admin);
    end if;

    v_message := 'Tu organización requiere ajustes antes de poder publicarse.';

    insert into public.notificaciones(user_id, tipo, mensaje, payload)
    values (NEW.owner_id, 'organizacion_rechazada', v_message, v_payload);
  end if;

  return NEW;
end;
$$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_organizacion_estado_notif') then
    create trigger trg_organizacion_estado_notif
    after update on public.organizaciones
    for each row execute function public.on_organizacion_estado_change();
  end if;
end $$;

-- ============================================================
-- 3) KYC / KYB DOCUMENTOS
-- ============================================================
create table if not exists public.kyc_documentos (
  id uuid primary key default gen_random_uuid(),
  owner_type text not null check (owner_type in ('user','organizacion')),
  owner_user_id uuid references auth.users(id) on delete cascade,
  owner_org_id uuid references public.organizaciones(id) on delete cascade,
  tipo text not null,
  archivo_url text not null,
  estado text not null default 'pendiente' check (estado in ('pendiente','aprobado','rechazado')),
  admin_id uuid references auth.users(id),
  notas_admin text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint kyc_owner_chk check(
    (owner_type='user' and owner_user_id is not null and owner_org_id is null) or
    (owner_type='organizacion' and owner_org_id is not null and owner_user_id is null)
  )
);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_kyc_touch') then
    create trigger trg_kyc_touch before update on public.kyc_documentos
    for each row execute function public.touch_updated_at();
  end if;
end $$;

-- ============================================================
-- 4) CATEGORÍAS
-- ============================================================
create table if not exists public.categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  descripcion text,
  icono text default 'category',
  color text default '#1976D2',
  activa boolean not null default true,
  orden int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_categorias_activa on public.categorias(activa);
create index if not exists idx_categorias_orden on public.categorias(orden);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_categorias_touch') then
    create trigger trg_categorias_touch before update on public.categorias
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  begin
    execute 'drop policy if exists categorias_public_read on public.categorias';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists categorias_admin_full_access on public.categorias';
  exception when others then null;
  end;
end $$;

create policy categorias_public_read on public.categorias
for select
to anon,authenticated
using (coalesce(activa, true));

create policy categorias_admin_full_access on public.categorias
for all
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

-- ============================================================
-- 5) SOLICITUDES Y CAMPAÑAS
-- ============================================================
create table if not exists public.solicitudes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  organizacion_id uuid references public.organizaciones(id) on delete set null,
  titulo text not null,
  descripcion text not null,
  tipo text not null default 'campania',
  categoria_id uuid references public.categorias(id) on delete set null,
  monto_objetivo numeric(12,2) check (monto_objetivo >= 0),
  portada_url text,
  qr_original_url text,
  estado text not null default 'pendiente' check (estado in ('pendiente','aprobada','rechazada','retirada')),
  motivo_rechazo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint solicitudes_tipo_chk check (tipo in ('campania','kermesse','rifa'))
);
create index if not exists idx_solicitudes_user on public.solicitudes(user_id);
create index if not exists idx_solicitudes_estado on public.solicitudes(estado);
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'solicitudes'
      and column_name = 'tipo'
  ) then
    alter table public.solicitudes
      add column tipo text not null default 'campania';
    alter table public.solicitudes
      add constraint solicitudes_tipo_chk check (tipo in ('campania','kermesse','rifa'));
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'solicitudes'
      and column_name = 'tipo'
  ) then
    begin
      alter table public.solicitudes alter column tipo set not null;
    exception when others then null;
    end;
    begin
      alter table public.solicitudes alter column tipo set default 'campania';
    exception when others then null;
    end;
    if not exists (
      select 1 from information_schema.table_constraints tc
      join information_schema.constraint_column_usage ccu
        on tc.constraint_name = ccu.constraint_name
     where tc.table_schema = 'public'
       and tc.table_name = 'solicitudes'
       and tc.constraint_type = 'CHECK'
       and tc.constraint_name = 'solicitudes_tipo_chk'
    ) then
      alter table public.solicitudes
        add constraint solicitudes_tipo_chk check (tipo in ('campania','kermesse','rifa'));
    end if;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_solicitudes_touch') then
    create trigger trg_solicitudes_touch before update on public.solicitudes
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  begin
    execute 'drop policy if exists solicitudes_select_self_or_admin on public.solicitudes';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists solicitudes_insert_self on public.solicitudes';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists solicitudes_update_self_pending on public.solicitudes';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists solicitudes_public_kermesse_read on public.solicitudes';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists solicitudes_admin_full_access on public.solicitudes';
  exception when others then null;
  end;
end $$;

create policy solicitudes_select_self_or_admin on public.solicitudes
for select
to authenticated
using (auth.uid() = user_id or public.is_admin(auth.uid()));

create policy solicitudes_insert_self on public.solicitudes
for insert
to authenticated
with check (
  auth.uid() = user_id
  and (
    organizacion_id is null
    or exists (
      select 1 from public.organizaciones o
      where o.id = organizacion_id and o.owner_id = auth.uid()
    )
  )
);

create policy solicitudes_update_self_pending on public.solicitudes
for update
to authenticated
using (auth.uid() = user_id and estado = 'pendiente')
with check (
  auth.uid() = user_id
  and estado = 'pendiente'
  and (
    organizacion_id is null
    or exists (
      select 1 from public.organizaciones o
      where o.id = organizacion_id and o.owner_id = auth.uid()
    )
  )
);

create policy solicitudes_public_kermesse_read on public.solicitudes
for select
to anon, authenticated
using (
  estado = 'aprobada'
  and tipo = 'kermesse'
);

create policy solicitudes_admin_full_access on public.solicitudes
for all
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

create or replace function public.on_solicitud_estado_change()
returns trigger
language plpgsql
as $$
declare
  v_message text;
  v_payload jsonb;
  v_campaign_id uuid;
begin
  if TG_OP <> 'UPDATE' then
    return NEW;
  end if;

  if NEW.estado = OLD.estado then
    return NEW;
  end if;

  if NEW.user_id is null then
    return NEW;
  end if;

  -- Obtener el ID de la campaña asociada si existe
  select id into v_campaign_id
  from public.campanias
  where solicitud_id = NEW.id
  limit 1;

  v_payload := jsonb_build_object(
    'solicitud_id', NEW.id,
    'tipo', NEW.tipo,
    'titulo', NEW.titulo
  );

  -- Agregar campaign_id al payload si existe
  if v_campaign_id is not null then
    v_payload := v_payload || jsonb_build_object('campaign_id', v_campaign_id);
  end if;

  if NEW.estado = 'aprobada' then
    case NEW.tipo
      when 'campania' then
        v_message := '¡Tu campaña fue aprobada y ya está visible para la comunidad!';
      when 'kermesse' then
        v_message := 'Tu evento solidario fue aprobado. Ya puede aparecer en la agenda.';
      when 'rifa' then
        v_message := 'Tu solicitud de rifa fue aprobada. Puedes comenzar a difundirla.';
      else
        v_message := 'Tu solicitud fue aprobada.';
    end case;

    insert into public.notificaciones(user_id, tipo, mensaje, payload)
    values (NEW.user_id, 'solicitud_aprobada', v_message, v_payload);

  elsif NEW.estado = 'rechazada' then
    if NEW.motivo_rechazo is not null and btrim(NEW.motivo_rechazo) <> '' then
      v_payload := v_payload || jsonb_build_object('motivo', NEW.motivo_rechazo);
    end if;

    case NEW.tipo
      when 'campania' then
        v_message := 'Tu campaña necesita ajustes antes de ser publicada.';
      when 'kermesse' then
        v_message := 'Tu evento solidario requiere cambios antes de aprobarse.';
      when 'rifa' then
        v_message := 'Tu solicitud de rifa necesita correcciones.';
      else
        v_message := 'Tu solicitud requiere correcciones.';
    end case;

    insert into public.notificaciones(user_id, tipo, mensaje, payload)
    values (NEW.user_id, 'solicitud_rechazada', v_message, v_payload);
  end if;

  return NEW;
end;
$$;

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_solicitud_estado_notif') then
    create trigger trg_solicitud_estado_notif
    after update on public.solicitudes
    for each row execute function public.on_solicitud_estado_change();
  end if;
end $$;

create table if not exists public.solicitud_reviews (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid not null references public.solicitudes(id) on delete cascade,
  admin_id uuid not null references auth.users(id),
  decision text not null check (decision in ('aprobada','rechazada')),
  motivo text,
  created_at timestamptz not null default now()
);

create table if not exists public.campanias (
  id uuid primary key default gen_random_uuid(),
  solicitud_id uuid unique references public.solicitudes(id) on delete set null,
  creador_id uuid not null references auth.users(id) on delete cascade,
  organizacion_id uuid references public.organizaciones(id) on delete set null,
  titulo text not null,
  descripcion_corta text,
  descripcion_larga text,
  categoria_id uuid references public.categorias(id) on delete set null,
  portada_url text,
  galeria jsonb not null default '[]'::jsonb,
  video_url text,
  monto_objetivo numeric(12,2) not null check (monto_objetivo > 0),
  monto_actual numeric(12,2) not null default 0,
  estado text not null default 'activa' check (estado in ('activa','finalizada','cancelada','suspendida','borrador')),
  fecha_inicio timestamptz not null default now(),
  fecha_fin timestamptz,
  etiquetas text[],
  slug text unique,
  evidencias_requeridas boolean not null default true,
  evidencias_hasta timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.on_campaign_insert_slug()
returns trigger language plpgsql as $$
begin
  if new.slug is null then new.slug := public.gen_slug(new.titulo); end if;
  return new;
end $$;
do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_campaign_slug') then
    create trigger trg_campaign_slug before insert on public.campanias
    for each row execute function public.on_campaign_insert_slug();
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_campanias_touch') then
    create trigger trg_campanias_touch before update on public.campanias
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  begin
    execute 'drop policy if exists campanias_public_read on public.campanias';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists campanias_creator_select on public.campanias';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists campanias_creator_insert on public.campanias';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists campanias_creator_update on public.campanias';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists campanias_admin_full_access on public.campanias';
  exception when others then null;
  end;
end $$;

create policy campanias_public_read on public.campanias
for select
to anon,authenticated
using (estado in ('activa','finalizada'));

create policy campanias_creator_select on public.campanias
for select
to authenticated
using (auth.uid() = creador_id);

create policy campanias_creator_insert on public.campanias
for insert
to authenticated
with check (
  auth.uid() = creador_id
  or public.is_admin(auth.uid())
);

create policy campanias_creator_update on public.campanias
for update
to authenticated
using (
  auth.uid() = creador_id
  or public.is_admin(auth.uid())
)
with check (
  auth.uid() = creador_id
  or public.is_admin(auth.uid())
);

create policy campanias_admin_full_access on public.campanias
for all
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

create or replace function public.publish_campaign_from_solicitud(
  p_solicitud_id uuid,
  p_admin_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_admin boolean;
  v_solicitud public.solicitudes%rowtype;
  v_short_description text;
  v_campaign_id uuid;
begin
  select public.is_admin(p_admin_id) into v_is_admin;
  if not coalesce(v_is_admin, false) then
    raise exception 'No tienes permisos para publicar campañas.' using errcode = '42501';
  end if;

  select *
    into v_solicitud
  from public.solicitudes
  where id = p_solicitud_id
  for update;

  if not found then
    raise exception 'No encontramos la solicitud indicada.' using errcode = 'P0002';
  end if;

  if v_solicitud.tipo <> 'campania' then
    raise exception 'Solo se pueden publicar solicitudes de tipo campaña.' using errcode = '22023';
  end if;

  if v_solicitud.monto_objetivo is null or v_solicitud.monto_objetivo <= 0 then
    raise exception 'La solicitud no tiene un monto objetivo válido.' using errcode = '22023';
  end if;

  v_short_description := trim(regexp_replace(coalesce(v_solicitud.descripcion, ''), '\s+', ' ', 'g'));
  if v_short_description = '' then
    v_short_description := coalesce(v_solicitud.titulo, 'Campaña solidaria');
  end if;
  if length(v_short_description) > 220 then
    v_short_description := rtrim(substr(v_short_description, 1, 217)) || '...';
  end if;

  insert into public.campanias (
    solicitud_id,
    creador_id,
    organizacion_id,
    titulo,
    descripcion_corta,
    descripcion_larga,
    categoria_id,
    portada_url,
    monto_objetivo,
    estado
  )
  values (
    v_solicitud.id,
    v_solicitud.user_id,
    v_solicitud.organizacion_id,
    v_solicitud.titulo,
    v_short_description,
    v_solicitud.descripcion,
    v_solicitud.categoria_id,
    v_solicitud.portada_url,
    v_solicitud.monto_objetivo,
    'activa'
  )
  on conflict (solicitud_id) do update
  set
    estado = 'activa',
    titulo = excluded.titulo,
    slug = public.gen_slug(excluded.titulo || '-' || extract(epoch from now())::text),
    descripcion_corta = excluded.descripcion_corta,
    descripcion_larga = excluded.descripcion_larga,
    categoria_id = excluded.categoria_id,
    organizacion_id = excluded.organizacion_id,
    portada_url = excluded.portada_url,
    monto_objetivo = excluded.monto_objetivo,
    updated_at = now()
  returning id into v_campaign_id;

  update public.solicitudes
  set estado = 'aprobada',
      motivo_rechazo = null,
      updated_at = now()
  where id = p_solicitud_id;

  insert into public.solicitud_reviews(id, solicitud_id, admin_id, decision, motivo, created_at)
  values (gen_random_uuid(), p_solicitud_id, p_admin_id, 'aprobada', null, now());

  return v_campaign_id;
end;
$$;

grant execute on function public.publish_campaign_from_solicitud(uuid, uuid) to authenticated;


-- ============================================================
-- 6) QR PROXY · Seguridad y transparencia
-- ============================================================

create table if not exists public.qr_sources (
  id uuid primary key default gen_random_uuid(),
  owner_type text not null check (owner_type in ('user','organizacion')),
  owner_user_id uuid references auth.users(id) on delete cascade,
  owner_org_id uuid references public.organizaciones(id) on delete cascade,
  label text,
  qr_real_url text not null,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  constraint qr_src_owner_chk check(
    (owner_type='user' and owner_user_id is not null and owner_org_id is null)
    or (owner_type='organizacion' and owner_org_id is not null and owner_user_id is null)
  )
);

create table if not exists public.qr_proxies (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  qr_source_id uuid not null references public.qr_sources(id) on delete restrict,
  qr_public_url text not null,
  estado text not null default 'activo' check (estado in ('activo','rotado','revocado')),
  rotacion int not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_qr_proxies_camp on public.qr_proxies(campania_id, estado);

create table if not exists public.qr_proxy_logs (
  id uuid primary key default gen_random_uuid(),
  qr_proxy_id uuid not null references public.qr_proxies(id) on delete cascade,
  ip text,
  user_agent text,
  referrer text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 7) RECOMPENSAS
-- ============================================================

create table if not exists public.recompensas (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  titulo text not null,
  descripcion text,
  monto_minimo numeric(12,2) not null check (monto_minimo >= 0),
  cantidad_limite int,
  cantidad_reclamada int not null default 0,
  imagen_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_recompensas_touch') then
    create trigger trg_recompensas_touch before update on public.recompensas
    for each row execute function public.touch_updated_at();
  end if;
end $$;

-- ============================================================
-- 8) DONACIONES (con comprobante y validación admin)
-- ============================================================

create table if not exists public.donaciones (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  recompensa_id uuid references public.recompensas(id) on delete set null,
  monto numeric(12,2) not null check (monto > 0),
  moneda text not null default 'BOB' check (moneda in ('BOB','USD')),
  comprobante_url text,
  mensaje text,
  metodo text not null default 'qr' check (metodo in ('qr','transferencia','otro')),
  referencia text,
  anonimo boolean not null default false,
  estado text not null default 'pendiente' check (estado in ('pendiente','aprobada','rechazada')),
  admin_validador uuid references auth.users(id),
  fecha_validacion timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Agregar columna moneda si no existe
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'donaciones'
      and column_name = 'moneda'
  ) then
    alter table public.donaciones add column moneda text not null default 'BOB' check (moneda in ('BOB','USD'));
  end if;
end $$;
create index if not exists idx_donaciones_camp_estado on public.donaciones(campania_id, estado);
create index if not exists idx_donaciones_user on public.donaciones(user_id);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_donaciones_touch') then
    create trigger trg_donaciones_touch before update on public.donaciones
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  begin
    execute 'drop policy if exists donaciones_public_read on public.donaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists donaciones_insert_self on public.donaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists donaciones_admin_manage on public.donaciones';
  exception when others then null;
  end;
end $$;

create policy donaciones_public_read on public.donaciones
for select
to authenticated
using (
  estado = 'aprobada'
  or auth.uid() = user_id
  or public.is_admin(auth.uid())
  or exists (
    select 1
    from public.campanias c
    where c.id = campania_id
      and c.creador_id = auth.uid()
  )
);

create policy donaciones_insert_self on public.donaciones
for insert
to authenticated
with check (auth.uid() = user_id);

create policy donaciones_admin_manage on public.donaciones
for all
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

do $$
begin
  begin
    execute 'drop function if exists public.get_campaign_payment_instructions(uuid)';
  exception when others then null;
  end;
end $$;

create or replace function public.get_campaign_payment_instructions(p_campaign_id uuid)
returns table (
  donacion_qr_url text,
  banco_titular text,
  banco_nombre text,
  banco_tipo_cuenta text,
  banco_numero_cuenta text,
  organizer_phone text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
    select
      prof.donacion_qr_url,
      prof.banco_titular,
      prof.banco_nombre,
      prof.banco_tipo_cuenta,
      prof.banco_numero_cuenta,
      prof.telefono as organizer_phone
    from public.campanias c
    join public.profiles prof on prof.user_id = c.creador_id
    where c.id = p_campaign_id
      and c.estado in ('activa','finalizada','suspendida');
end;
$$;

grant execute on function public.get_campaign_payment_instructions(uuid) to anon, authenticated;

-- ============================================================
-- FUNCIÓN: Obtener monto máximo permitido para donar
-- ============================================================
create or replace function public.get_campaign_max_donation_amount(p_campaign_id uuid)
returns table (
  max_amount numeric,
  remaining_amount numeric,
  goal_amount numeric,
  current_amount numeric,
  is_goal_reached boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_goal numeric;
  v_current numeric;
  v_remaining numeric;
begin
  -- Obtener montos de la campaña
  select monto_objetivo, monto_actual
    into v_goal, v_current
  from public.campanias
  where id = p_campaign_id
    and estado in ('activa', 'suspendida');

  -- Si no se encuentra la campaña, retornar NULL
  if not found then
    return;
  end if;

  -- Calcular monto restante
  v_remaining := greatest(v_goal - v_current, 0);

  return query
    select
      v_remaining as max_amount,
      v_remaining as remaining_amount,
      v_goal as goal_amount,
      v_current as current_amount,
      (v_current >= v_goal) as is_goal_reached;
end;
$$;

grant execute on function public.get_campaign_max_donation_amount(uuid) to anon, authenticated;

create or replace function public.on_donacion_aprobada()
returns trigger language plpgsql 
security definer
set search_path = public
as $$
declare
  v_campaign_title text;
  v_campaign_descripcion text;
  v_campaign_creator_id uuid;
  v_campaign_creator_name text;
  v_reward_id uuid;
  v_reward_titulo text;
  v_donante_id uuid;
  v_donante_name text;
  v_donante_email text;
  v_metodo_pago text;
begin
  -- Solo procesar cuando es UPDATE
  if TG_OP <> 'UPDATE' then
    return NEW;
  end if;

  -- Solo actuar cuando cambia el estado
  if NEW.estado = OLD.estado then
    return NEW;
  end if;

  -- Obtener datos COMPLETOS de la campaña
  select c.titulo, c.descripcion_corta, c.creador_id, p.display_name
    into v_campaign_title, v_campaign_descripcion, v_campaign_creator_id, v_campaign_creator_name
  from public.campanias c
  left join public.profiles p on p.user_id = c.creador_id
  where c.id = NEW.campania_id;

  -- Obtener datos COMPLETOS del donante
  select p.display_name, u.email
    into v_donante_name, v_donante_email
  from auth.users u
  left join public.profiles p on p.user_id = u.id
  where u.id = NEW.user_id;

  -- Guardar el user_id del donante de forma explícita
  v_donante_id := NEW.user_id;
  
  -- Obtener método de pago (la columna se llama 'metodo')
  v_metodo_pago := coalesce(NEW.metodo, 'No especificado');

  -- === ESTADO: APROBADA ===
  if NEW.estado = 'aprobada' then
    
    -- Asignar recompensa automáticamente si no tiene
    if NEW.recompensa_id is null then
      select r.id into v_reward_id
      from public.recompensas r
      where r.campania_id = NEW.campania_id
        and r.monto_minimo <= NEW.monto
        and (r.cantidad_limite is null or r.cantidad_reclamada < r.cantidad_limite)
      order by r.monto_minimo desc
      limit 1;

      if v_reward_id is not null then
        update public.donaciones
          set recompensa_id = v_reward_id
        where id = NEW.id;
        NEW.recompensa_id = v_reward_id;
        
        -- Obtener título de la recompensa
        select titulo into v_reward_titulo
        from public.recompensas
        where id = v_reward_id;
      end if;
    end if;

    -- Actualizar monto de campaña
    update public.campanias
      set monto_actual = monto_actual + NEW.monto,
          updated_at = now()
      where id = NEW.campania_id;

    -- Actualizar contador de recompensa
    if NEW.recompensa_id is not null then
      update public.recompensas
        set cantidad_reclamada = cantidad_reclamada + 1,
            updated_at = now()
      where id = NEW.recompensa_id
        and (cantidad_limite is null or cantidad_reclamada < cantidad_limite);
    end if;

    -- NOTIFICACIÓN 1: Para el CREADOR de la campaña (solo si NO es el mismo donante)
    if v_campaign_creator_id is not null and v_campaign_creator_id <> v_donante_id then
      insert into public.notificaciones(user_id, tipo, mensaje, payload)
      values (
        v_campaign_creator_id,  -- ID del creador de la campaña
        'donacion_aprobada',
        case
          when v_campaign_title is not null and btrim(v_campaign_title) <> '' then
            format('Se aprobó una donación en tu campaña "%s".', v_campaign_title)
          else
            'Se aprobó una donación en tu campaña.'
        end,
        jsonb_build_object(
          'campaign_id', NEW.campania_id,
          'titulo', v_campaign_title,
          'monto', NEW.monto,
          'estado', 'Aprobada',
          'donante', coalesce(v_donante_name, 'Anónimo'),
          'email_donante', v_donante_email,
          'metodo_pago', v_metodo_pago,
          'fecha_donacion', to_char(NEW.created_at, 'DD/MM/YYYY HH24:MI'),
          'fecha_aprobacion', to_char(now(), 'DD/MM/YYYY HH24:MI'),
          'recompensa', coalesce(v_reward_titulo, 'Sin recompensa'),
          'mensaje_donante', coalesce(NEW.mensaje, 'Sin mensaje'),
          'section', 'donors'
        )
      );
    end if;

    -- NOTIFICACIÓN 2: Para el DONANTE (usuario que hizo la donación)
    if v_donante_id is not null then
      insert into public.notificaciones(user_id, tipo, mensaje, payload)
      values (
        v_donante_id,  -- ID del usuario que donó
        'donacion_confirmada',
        case
          when v_campaign_title is not null and btrim(v_campaign_title) <> '' then
            format('¡Gracias! Tu donación a "%s" fue aprobada.', v_campaign_title)
          else
            '¡Gracias! Tu donación fue aprobada.'
        end,
        jsonb_build_object(
          'campaign_id', NEW.campania_id,
          'titulo', v_campaign_title,
          'descripcion', coalesce(v_campaign_descripcion, 'Sin descripción'),
          'monto', NEW.monto,
          'estado', 'Aprobada',
          'creador', coalesce(v_campaign_creator_name, 'Organizador'),
          'metodo_pago', v_metodo_pago,
          'fecha_donacion', to_char(NEW.created_at, 'DD/MM/YYYY HH24:MI'),
          'fecha_aprobacion', to_char(now(), 'DD/MM/YYYY HH24:MI'),
          'recompensa', coalesce(v_reward_titulo, 'Sin recompensa asignada'),
          'tu_mensaje', coalesce(NEW.mensaje, 'Sin mensaje'),
          'section', 'donors'
        )
      );
    end if;

  -- === ESTADO: RECHAZADA ===
  elsif NEW.estado = 'rechazada' then
    
    -- NOTIFICACIÓN: Para el DONANTE
    if v_donante_id is not null then
      insert into public.notificaciones(user_id, tipo, mensaje, payload)
      values (
        v_donante_id,  -- ID del usuario que donó
        'donacion_rechazada',
        case
          when v_campaign_title is not null and btrim(v_campaign_title) <> '' then
            format('Tu donación a "%s" necesita correcciones.', v_campaign_title)
          else
            'Tu donación requiere correcciones.'
        end,
        jsonb_build_object(
          'titulo', v_campaign_title,
          'monto', NEW.monto,
          'estado', 'Rechazada',
          'creador', coalesce(v_campaign_creator_name, 'Organizador'),
          'metodo_pago', v_metodo_pago,
          'fecha_donacion', to_char(NEW.created_at, 'DD/MM/YYYY HH24:MI'),
          'fecha_rechazo', to_char(now(), 'DD/MM/YYYY HH24:MI'),
          'motivo', 'Por favor revisa los datos de tu donación y vuelve a intentarlo'
        )
      );
    end if;
    
  end if;

  -- === NOTIFICAR CAMBIO DE RANKING ===
  -- Solo notificar si la donación fue aprobada y el usuario entró o mejoró en el TOP 10
  if NEW.estado = 'aprobada' and v_donante_id is not null then
    declare
      v_posicion_actual int;
      v_posicion_anterior int;
      v_total_donado numeric;
      v_trophy_level text;
    begin
      -- Calcular posición actual del donante
      with ranking as (
        select 
          d.user_id,
          row_number() over (
            order by sum(d.monto) desc, count(*) desc, d.user_id
          ) as posicion
        from public.donaciones d
        where d.estado = 'aprobada' and d.user_id is not null
        group by d.user_id
      )
      select r.posicion into v_posicion_actual
      from ranking r
      where r.user_id = v_donante_id;

      -- Calcular posición anterior (antes de esta donación)
      with ranking_anterior as (
        select 
          d.user_id,
          row_number() over (
            order by sum(d.monto) desc, count(*) desc, d.user_id
          ) as posicion
        from public.donaciones d
        where d.estado = 'aprobada' 
          and d.user_id is not null
          and d.id <> NEW.id  -- Excluir la donación actual
        group by d.user_id
      )
      select r.posicion into v_posicion_anterior
      from ranking_anterior r
      where r.user_id = v_donante_id;

      -- Calcular total donado
      select coalesce(sum(monto), 0) into v_total_donado
      from public.donaciones
      where user_id = v_donante_id and estado = 'aprobada';

      -- Obtener nivel de trofeo
      v_trophy_level := public.resolve_trophy_level(v_posicion_actual, v_total_donado);

      -- Notificar si entró al TOP 10 o mejoró su posición
      if v_posicion_actual <= 10 and (v_posicion_anterior is null or v_posicion_anterior > 10) then
        -- Entró al TOP 10 por primera vez
        insert into public.notificaciones(user_id, tipo, mensaje, payload)
        values (
          v_donante_id,
          'ranking_entrada',
          format('¡Felicidades! Entraste al TOP 10 del ranking en la posición #%s', v_posicion_actual),
          jsonb_build_object(
            'posicion', v_posicion_actual,
            'posicion_anterior', v_posicion_anterior,
            'total_donado', v_total_donado,
            'trophy_level', v_trophy_level,
            'section', 'ranking',
            'navigation_type', 'ranking'
          )
        );
      elsif v_posicion_actual <= 10 and v_posicion_anterior is not null and v_posicion_anterior <= 10 and v_posicion_actual < v_posicion_anterior then
        -- Mejoró su posición dentro del TOP 10
        insert into public.notificaciones(user_id, tipo, mensaje, payload)
        values (
          v_donante_id,
          'ranking_mejora',
          format('¡Subiste al puesto #%s del ranking! (Antes: #%s)', v_posicion_actual, v_posicion_anterior),
          jsonb_build_object(
            'posicion', v_posicion_actual,
            'posicion_anterior', v_posicion_anterior,
            'total_donado', v_total_donado,
            'trophy_level', v_trophy_level,
            'section', 'ranking',
            'navigation_type', 'ranking'
          )
        );
      elsif v_posicion_actual <= 3 and v_posicion_anterior is not null and v_posicion_actual < v_posicion_anterior then
        -- Entró al podio (TOP 3)
        insert into public.notificaciones(user_id, tipo, mensaje, payload)
        values (
          v_donante_id,
          'ranking_podio',
          format('🏆 ¡Increíble! Llegaste al puesto #%s del podio', v_posicion_actual),
          jsonb_build_object(
            'posicion', v_posicion_actual,
            'posicion_anterior', v_posicion_anterior,
            'total_donado', v_total_donado,
            'trophy_level', v_trophy_level,
            'section', 'ranking',
            'navigation_type', 'ranking'
          )
        );
      end if;
    end;
  end if;

  return NEW;
end $$;
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_on_donacion_aprobada') then
    create trigger trg_on_donacion_aprobada
    after update on public.donaciones
    for each row execute function public.on_donacion_aprobada();
  end if;
end $$;

create or replace function public.resolve_trophy_level(p_rank integer, p_total numeric)
returns text
language plpgsql
immutable
as $$
declare
  v_total numeric := coalesce(p_total, 0);
begin
  if p_rank = 1 then
    return 'top_1';
  elsif p_rank = 2 then
    return 'top_2';
  elsif p_rank = 3 then
    return 'top_3';
  elsif v_total >= 2000 then
    return 'legend';
  elsif v_total >= 1000 then
    return 'champion';
  elsif v_total >= 500 then
    return 'hero';
  elsif v_total >= 250 then
    return 'ally';
  elsif v_total >= 100 then
    return 'supporter';
  elsif v_total >= 50 then
    return 'friend';
  else
    return 'starter';
  end if;
end;
$$;

create or replace function public.get_donor_leaderboard(p_limit integer default 20)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  total_donated numeric,
  donations_count integer,
  "position" integer,
  trophy_level text
)
language sql
security definer
set search_path = public
as $$
  with totals as (
    select
      d.user_id,
      count(*) filter (where d.estado = 'aprobada')::int as donations_count,
      coalesce(sum(d.monto) filter (where d.estado = 'aprobada'), 0)::numeric as total_donated
    from public.donaciones d
    where d.user_id is not null
    group by d.user_id
  ),
  ranked as (
    select
      t.user_id,
      t.donations_count,
      t.total_donated,
      (row_number() over (
        order by t.total_donated desc, t.donations_count desc, t.user_id
      ))::int as ranking_position
    from totals t
    where t.donations_count > 0 and t.total_donated > 0
  )
  select
    r.user_id,
    coalesce(p.display_name, 'Donante solidario') as display_name,
    p.avatar_url,
    r.total_donated,
    r.donations_count,
    r.ranking_position as "position",
    public.resolve_trophy_level(r.ranking_position, r.total_donated) as trophy_level
  from ranked r
  left join public.profiles p on p.user_id = r.user_id
  order by r.ranking_position
  limit greatest(coalesce(p_limit, 20), 3);
$$;

grant execute on function public.get_donor_leaderboard(integer) to anon, authenticated;

create or replace function public.get_current_user_trophy_profile()
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  total_donated numeric,
  donations_count integer,
  "position" integer,
  trophy_level text,
  current_level_min_amount numeric,
  next_level_amount numeric,
  next_level_level text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_donations_count integer := 0;
  v_total numeric := 0;
  v_position integer;
  v_level text;
  v_current_min numeric;
  v_next_amount numeric;
  v_next_level text;
begin
  if auth.uid() is null then
    return;
  end if;

  select
    count(*) filter (where d.estado = 'aprobada')::int,
    coalesce(sum(d.monto) filter (where d.estado = 'aprobada'), 0)::numeric
  into v_donations_count, v_total
  from public.donaciones d
  where d.user_id = auth.uid();

  if v_donations_count > 0 and v_total > 0 then
    select ranking_position
      into v_position
    from (
      select
        inner_d.user_id,
        (row_number() over (
          order by inner_d.total_donated desc, inner_d.donations_count desc, inner_d.user_id
        ))::int as ranking_position
      from (
        select
          d.user_id,
          count(*) filter (where d.estado = 'aprobada')::int as donations_count,
          coalesce(sum(d.monto) filter (where d.estado = 'aprobada'), 0)::numeric as total_donated
        from public.donaciones d
        where d.user_id is not null
        group by d.user_id
      ) as inner_d
      where inner_d.donations_count > 0 and inner_d.total_donated > 0
    ) as ranked
    where ranked.user_id = auth.uid();
  else
    v_position := null;
  end if;

  v_level := public.resolve_trophy_level(v_position, v_total);

  if v_level in ('top_1', 'top_2', 'top_3') then
    v_current_min := v_total;
    v_next_amount := null;
    v_next_level := null;
  elsif v_level = 'legend' then
    v_current_min := 2000;
    v_next_amount := null;
    v_next_level := null;
  elsif v_level = 'champion' then
    v_current_min := 1000;
    v_next_amount := 2000;
    v_next_level := 'legend';
  elsif v_level = 'hero' then
    v_current_min := 500;
    v_next_amount := 1000;
    v_next_level := 'champion';
  elsif v_level = 'ally' then
    v_current_min := 250;
    v_next_amount := 500;
    v_next_level := 'hero';
  elsif v_level = 'supporter' then
    v_current_min := 100;
    v_next_amount := 250;
    v_next_level := 'ally';
  elsif v_level = 'friend' then
    v_current_min := 50;
    v_next_amount := 100;
    v_next_level := 'supporter';
  else
    v_current_min := 0;
    v_next_amount := 50;
    v_next_level := 'friend';
  end if;

  return query
    select
      u.user_id,
      coalesce(p.display_name, 'Donante solidario') as display_name,
      p.avatar_url,
      v_total,
      v_donations_count,
      v_position,
      v_level,
      v_current_min,
      v_next_amount,
      v_next_level
    from (select auth.uid() as user_id) as u
    left join public.profiles p on p.user_id = u.user_id;
end;
$$;

grant execute on function public.get_current_user_trophy_profile() to authenticated;

-- ============================================================
-- 9) EVIDENCIAS
-- ============================================================

create table if not exists public.evidencias (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  url text not null,
  tipo text check (tipo in ('foto','video','documento')),
  descripcion text,
  visibilidad text not null default 'donadores' check (visibilidad in ('donadores','publico')),
  created_at timestamptz not null default now()
);
create index if not exists idx_evidencias_camp on public.evidencias(campania_id);

-- ============================================================
-- 10) COMENTARIOS y FAVORITOS
-- ============================================================

create table if not exists public.comentarios (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete set null,
  parent_id uuid references public.comentarios(id) on delete set null,
  contenido text not null,
  estado text not null default 'visible' check (estado in ('visible','oculto','eliminado')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'comentarios'
      and column_name = 'autor_nombre'
  ) then
    alter table public.comentarios add column autor_nombre text;
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'comentarios'
      and column_name = 'autor_avatar_url'
  ) then
    alter table public.comentarios add column autor_avatar_url text;
  end if;
end $$;
create index if not exists idx_comentarios_camp on public.comentarios(campania_id);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_comments_touch') then
    create trigger trg_comments_touch before update on public.comentarios
    for each row execute function public.touch_updated_at();
  end if;
end $$;

do $$
begin
  begin
    execute 'drop policy if exists comentarios_select_visible on public.comentarios';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists comentarios_insert_self on public.comentarios';
  exception when others then null;
  end;
end $$;

create policy comentarios_select_visible on public.comentarios
for select
to anon, authenticated
using (estado = 'visible');

create policy comentarios_insert_self on public.comentarios
for insert
to authenticated
with check (auth.uid() = user_id);

create table if not exists public.favoritos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  campania_id uuid not null references public.campanias(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id,campania_id)
);

do $$
begin
  begin
    execute 'drop policy if exists favoritos_select_self on public.favoritos';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists favoritos_insert_self on public.favoritos';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists favoritos_delete_self on public.favoritos';
  exception when others then null;
  end;
end $$;

create policy favoritos_select_self on public.favoritos
for select
to authenticated
using (auth.uid() = user_id);

create policy favoritos_insert_self on public.favoritos
for insert
to authenticated
with check (auth.uid() = user_id);

create policy favoritos_delete_self on public.favoritos
for delete
to authenticated
using (auth.uid() = user_id);

-- ============================================================
-- 11) EVENTOS · Mapa solidario
-- ============================================================

create table if not exists public.eventos (
  id uuid primary key default gen_random_uuid(),
  organizador_user_id uuid references auth.users(id) on delete set null,
  organizacion_id uuid references public.organizaciones(id) on delete set null,
  titulo text not null,
  descripcion text,
  categoria_id uuid references public.categorias(id) on delete set null,
  fecha_inicio timestamptz not null,
  fecha_fin timestamptz,
  lat numeric(10,7),
  lng numeric(10,7),
  direccion text,
  portada_url text,
  estado text not null default 'programado' check (estado in ('programado','en_curso','finalizado','cancelado')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_eventos_time on public.eventos(fecha_inicio,fecha_fin);
create index if not exists idx_eventos_geo on public.eventos(lat,lng);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_eventos_touch') then
    create trigger trg_eventos_touch before update on public.eventos
    for each row execute function public.touch_updated_at();
  end if;
end $$;

-- ============================================================
-- 12) NOTIFICACIONES + HITOS automáticos
-- ============================================================

create table if not exists public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tipo text not null,
  mensaje text not null,
  payload jsonb not null default '{}'::jsonb,
  leido boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notif_user on public.notificaciones(user_id,leido);

do $$
begin
  begin
    execute 'drop policy if exists notificaciones_select_self on public.notificaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists notificaciones_update_self on public.notificaciones';
  exception when others then null;
  end;
  begin
    execute 'drop policy if exists notificaciones_select_admin on public.notificaciones';
  exception when others then null;
  end;
end $$;

drop policy if exists notificaciones_insert_flow on public.notificaciones;

create policy notificaciones_select_self on public.notificaciones
for select
to authenticated
using (user_id = auth.uid());

create policy notificaciones_update_self on public.notificaciones
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy notificaciones_select_admin on public.notificaciones
for select
to authenticated
using (public.is_admin(auth.uid()));

create policy notificaciones_insert_flow on public.notificaciones
for insert
to authenticated
with check (
  public.is_admin(auth.uid())
  or user_id = auth.uid()
  or public.is_admin(user_id)
  or auth.uid() is null
);

create or replace function public.get_user_notifications(p_limit integer default 50)
returns setof public.notificaciones
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
    select *
    from public.notificaciones
    where user_id = auth.uid()
    order by created_at desc
    limit coalesce(p_limit, 50);
end;
$$;

grant execute on function public.get_user_notifications(integer) to authenticated;

create or replace function public.mark_notification_as_read(p_notification_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.notificaciones
     set leido = true
   where id = p_notification_id
     and user_id = auth.uid();

  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

create or replace function public.mark_notifications_as_read()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.notificaciones
     set leido = true
   where user_id = auth.uid()
     and leido = false;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

grant execute on function public.mark_notification_as_read(uuid) to authenticated;
grant execute on function public.mark_notifications_as_read() to authenticated;

-- ============================================================
-- NOTIFICACIONES DE COMENTARIOS
-- ============================================================

create or replace function public.notify_new_comment()
returns trigger language plpgsql as $$
declare
  v_campaign_creator_id uuid;
  v_campaign_title text;
  v_commenter_name text;
begin
  -- Obtener datos de la campaña y el creador
  select c.creador_id, c.titulo
    into v_campaign_creator_id, v_campaign_title
  from public.campanias c
  where c.id = NEW.campania_id;

  -- Obtener nombre del comentarista
  select display_name into v_commenter_name
  from public.profiles
  where user_id = NEW.user_id;

  -- Solo notificar al creador si no es él quien comentó
  if v_campaign_creator_id is not null and v_campaign_creator_id <> NEW.user_id then
    insert into public.notificaciones(user_id, tipo, mensaje, payload)
    values (
      v_campaign_creator_id,
      'nuevo_comentario',
      format('%s comentó en tu campaña "%s"', 
        coalesce(v_commenter_name, 'Alguien'), 
        v_campaign_title),
      jsonb_build_object(
        'campaign_id', NEW.campania_id,
        'comment_id', NEW.id,
        'commenter_name', v_commenter_name,
        'titulo', v_campaign_title,
        'contenido', left(NEW.contenido, 100),
        'section', 'comments',
        'navigation_type', 'campaign'
      )
    );
  end if;

  return NEW;
end $$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_notify_new_comment') then
    create trigger trg_notify_new_comment
    after insert on public.comentarios
    for each row execute function public.notify_new_comment();
  end if;
end $$;

create table if not exists public.campania_hitos (
  id uuid primary key default gen_random_uuid(),
  campania_id uuid not null references public.campanias(id) on delete cascade,
  hito int not null check (hito in (25,50,75,100)),
  unique(campania_id,hito),
  created_at timestamptz not null default now()
);

create or replace function public.on_campania_monto_notifs()
returns trigger language plpgsql as $$
declare 
  pct numeric;
  pct_old numeric;
  needed int; 
  creator uuid;
  v_slug text;
  v_titulo text;
  hitos_alcanzados int[];
  hito_mayor int;
begin
  if NEW.monto_objetivo <= 0 then return NEW; end if;
  
  pct := (NEW.monto_actual / NEW.monto_objetivo) * 100;
  pct_old := (OLD.monto_actual / OLD.monto_objetivo) * 100;
  
  -- Obtener información de la campaña
  select creador_id, slug, titulo into creator, v_slug, v_titulo 
  from public.campanias 
  where id=NEW.id;

  -- Determinar qué hitos se alcanzaron en esta actualización
  hitos_alcanzados := array[]::int[];
  
  for needed in select unnest(array[25,50,75,100]) loop
    if pct >= needed and pct_old < needed and not exists (
      select 1 from public.campania_hitos where campania_id=NEW.id and hito=needed
    ) then
      hitos_alcanzados := hitos_alcanzados || needed;
    end if;
  end loop;

  -- Si se alcanzaron múltiples hitos, solo notificar el mayor
  if array_length(hitos_alcanzados, 1) > 0 then
    hito_mayor := hitos_alcanzados[array_upper(hitos_alcanzados, 1)];
    
    -- Registrar todos los hitos alcanzados
    foreach needed in array hitos_alcanzados loop
      insert into public.campania_hitos(campania_id,hito) values(NEW.id,needed);
    end loop;
    
    -- Notificar solo el hito mayor
    insert into public.notificaciones(user_id,tipo,mensaje,payload)
    values(creator,'campania_'||hito_mayor,
           format('Tu campaña alcanzó el %s%% de la meta.',hito_mayor),
           jsonb_build_object(
             'campaign_id', NEW.id,
             'campania_id', NEW.id,
             'slug', v_slug,
             'titulo', v_titulo,
             'porcentaje', hito_mayor,
             'monto_actual', NEW.monto_actual,
             'monto_objetivo', NEW.monto_objetivo,
             'section', 'progress'
           ));
  end if;
  
  -- Marcar como finalizada cuando alcanza el 100% del objetivo
  if pct >= 100 and NEW.estado = 'activa' then
    NEW.estado := 'finalizada';
    NEW.fecha_fin := now();
  end if;
  
  return NEW;
end $$;
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_campania_monto_notifs') then
    create trigger trg_campania_monto_notifs
    after update of monto_actual on public.campanias
    for each row execute function public.on_campania_monto_notifs();
  end if;
end $$;

create or replace function public.notify_admins_new_solicitud()
returns trigger language plpgsql as $$
begin
  insert into public.notificaciones(user_id, tipo, mensaje, payload)
  select p.user_id,
         'solicitud_nueva',
         format('Nueva solicitud registrada: %s', NEW.titulo),
         jsonb_build_object('solicitud_id', NEW.id, 'titulo', NEW.titulo, 'user_id', NEW.user_id)
  from public.profiles p
  where p.is_admin is true;

  return NEW;
end $$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_notify_admin_solicitud') then
    create trigger trg_notify_admin_solicitud
    after insert on public.solicitudes
    for each row execute function public.notify_admins_new_solicitud();
  end if;
end $$;

-- ============================================================
-- 13) AUDITORÍA + REPORTES
-- ============================================================

create table if not exists public.auditoria (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  accion text not null,
  entidad text not null,
  entidad_id uuid,
  detalles jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.reportes (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('campania','comentario','update','recompensa')),
  target_id uuid not null,
  reporter_id uuid references auth.users(id) on delete set null,
  motivo text not null,
  estado text not null default 'abierto' check (estado in ('abierto','en_revision','resuelto','descartado')),
  admin_id uuid references auth.users(id),
  notas_admin text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $$ begin
  if not exists (select 1 from pg_trigger where tgname='trg_reportes_touch') then
    create trigger trg_reportes_touch before update on public.reportes
    for each row execute function public.touch_updated_at();
  end if;
end $$;

-- ============================================================
-- 14) VISTA PÚBLICA de campañas
-- ============================================================

create or replace view public.v_campania_publica as
select
  c.id, c.slug, c.titulo, c.descripcion_corta, c.portada_url,
  c.monto_objetivo, c.monto_actual,
  case when c.monto_objetivo>0 then round((c.monto_actual/c.monto_objetivo)*100,2) else 0 end as porcentaje,
  c.fecha_inicio, c.fecha_fin, c.estado,
  cat.nombre as categoria,
  (select count(*) from public.donaciones d where d.campania_id=c.id and d.estado='aprobada') as donadores
from public.campanias c
left join public.categorias cat on cat.id=c.categoria_id
where c.estado in ('activa','finalizada');

create or replace function public.list_public_campaigns(
  p_category text default null,
  p_limit integer default null
)
returns table (
  id uuid,
  slug text,
  titulo text,
  descripcion_corta text,
  portada_url text,
  monto_objetivo numeric,
  monto_actual numeric,
  porcentaje numeric,
  fecha_inicio timestamptz,
  fecha_fin timestamptz,
  estado text,
  categoria text,
  donadores integer,
  organizacion_nombre text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
    select
      c.id,
      c.slug,
      c.titulo,
      coalesce(c.descripcion_corta, ''),
      coalesce(c.portada_url, ''),
      c.monto_objetivo,
      c.monto_actual,
      case
        when c.monto_objetivo > 0 then round((c.monto_actual / c.monto_objetivo) * 100, 2)
        else 0
      end,
      c.fecha_inicio,
      c.fecha_fin,
      c.estado,
      cat.nombre as categoria,
      coalesce((
        select count(*)::int
        from public.donaciones d
        where d.campania_id = c.id
          and d.estado = 'aprobada'
      ), 0) as donadores,
      org.nombre as organizacion_nombre
    from public.campanias c
    left join public.categorias cat on cat.id = c.categoria_id
    left join public.organizaciones org on org.id = c.organizacion_id
    where c.estado in ('activa', 'finalizada')
      and (
        p_category is null
        or cat.nombre = p_category
      )
    order by c.fecha_inicio desc nulls last
    limit coalesce(p_limit, 50);
end;
$$;

grant execute on function public.list_public_campaigns(text, integer) to anon, authenticated;

create or replace function public.search_public_campaigns(
  p_term text,
  p_limit integer default null
)
returns table (
  id uuid,
  slug text,
  titulo text,
  descripcion_corta text,
  portada_url text,
  monto_objetivo numeric,
  monto_actual numeric,
  porcentaje numeric,
  fecha_inicio timestamptz,
  fecha_fin timestamptz,
  estado text,
  categoria text,
  donadores integer,
  organizacion_nombre text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_term text;
begin
  normalized_term := '%' || trim(coalesce(p_term, '')) || '%';

  if length(trim(coalesce(p_term, ''))) = 0 then
    return query
      select *
      from public.list_public_campaigns(null, coalesce(p_limit, 40));
  end if;

  return query
    select
      c.id,
      c.slug,
      c.titulo,
      coalesce(c.descripcion_corta, ''),
      coalesce(c.portada_url, ''),
      c.monto_objetivo,
      c.monto_actual,
      case
        when c.monto_objetivo > 0 then round((c.monto_actual / c.monto_objetivo) * 100, 2)
        else 0
      end,
      c.fecha_inicio,
      c.fecha_fin,
      c.estado,
      cat.nombre as categoria,
      coalesce((
        select count(*)::int
        from public.donaciones d
        where d.campania_id = c.id
          and d.estado = 'aprobada'
      ), 0) as donadores,
      org.nombre as organizacion_nombre
    from public.campanias c
    left join public.categorias cat on cat.id = c.categoria_id
    left join public.organizaciones org on org.id = c.organizacion_id
    where c.estado in ('activa', 'finalizada')
      and (
        c.titulo ilike normalized_term
        or coalesce(c.descripcion_corta, '') ilike normalized_term
        or coalesce(cat.nombre, '') ilike normalized_term
        or coalesce(org.nombre, '') ilike normalized_term
      )
    order by c.fecha_inicio desc nulls last
    limit coalesce(p_limit, 40);
end;
$$;

grant execute on function public.search_public_campaigns(text, integer) to anon, authenticated;

-- ============================================================
-- 15) STORAGE BUCKETS + POLÍTICAS (versión compatible 2025)
-- ============================================================

insert into storage.buckets (id,name,public)
values
  ('evidencias','evidencias',true),
  ('comprobantes','comprobantes',true),
  ('documentos','documentos',false),
  ('perfiles','perfiles',true)
on conflict (id) do nothing;

do $$
declare p text;
begin
  for p in select unnest(array[
    'evidencias_public_read','evidencias_creator_upload',
    'comprobantes_public_read','comprobantes_owner_upload',
    'documentos_owner_upload','documentos_owner_update','documentos_admin_read',
    'perfiles_public_read','perfiles_owner_upload'
  ]) loop
    begin execute format('drop policy if exists %I on storage.objects;',p);
    exception when others then null; end;
  end loop;
end $$;

-- Evidencias
create policy evidencias_public_read on storage.objects
for select to anon,authenticated using (bucket_id='evidencias');
create policy evidencias_creator_upload on storage.objects
for insert to authenticated
with check (
  bucket_id='evidencias'
  and (storage.foldername(name))[1]='campanias'
  and exists (
    select 1 from public.campanias c
    where c.id::text=(storage.foldername(name))[2]
      and (c.creador_id=auth.uid() or public.is_admin(auth.uid()))
  )
);

-- Comprobantes
create policy comprobantes_public_read on storage.objects
for select to anon,authenticated using (bucket_id='comprobantes');
create policy comprobantes_owner_upload on storage.objects
for insert to authenticated
with check (
  bucket_id='comprobantes'
  and (storage.foldername(name))[1]='users'
  and (storage.foldername(name))[2]=auth.uid()::text
);

-- Documentos KYC
create policy documentos_owner_upload on storage.objects
for insert to authenticated
with check (
  bucket_id='documentos'
  and (storage.foldername(name))[1] in ('users','organizaciones')
  and (
    ((storage.foldername(name))[1]='users' and (storage.foldername(name))[2]=auth.uid()::text)
    or public.is_admin(auth.uid())
  )
);
create policy documentos_owner_update on storage.objects
for update to authenticated
using (
  bucket_id='documentos'
  and (storage.foldername(name))[1] in ('users','organizaciones')
  and (
    ((storage.foldername(name))[1]='users' and (storage.foldername(name))[2]=auth.uid()::text)
    or public.is_admin(auth.uid())
  )
)
with check (
  bucket_id='documentos'
  and (storage.foldername(name))[1] in ('users','organizaciones')
  and (
    ((storage.foldername(name))[1]='users' and (storage.foldername(name))[2]=auth.uid()::text)
    or public.is_admin(auth.uid())
  )
);
create policy documentos_admin_read on storage.objects
for select to authenticated
using (bucket_id='documentos' and public.is_admin(auth.uid()));

-- Perfiles (logo/avatares)
create policy perfiles_public_read on storage.objects
for select to anon,authenticated using (bucket_id='perfiles');
create policy perfiles_owner_upload on storage.objects
for insert to authenticated
with check (
  bucket_id='perfiles'
  and (storage.foldername(name))[1] in ('users','organizaciones')
  and (
    ((storage.foldername(name))[1]='users' and (storage.foldername(name))[2]=auth.uid()::text)
    or public.is_admin(auth.uid())
  )
);

-- ============================================================
-- 16) RLS · ACTIVACIÓN
-- ============================================================

alter table public.profiles enable row level security;
alter table public.organizaciones enable row level security;
alter table public.kyc_documentos enable row level security;
alter table public.categorias enable row level security;
alter table public.solicitudes enable row level security;
alter table public.campanias enable row level security;
alter table public.donaciones enable row level security;
alter table public.evidencias enable row level security;
alter table public.comentarios enable row level security;
alter table public.favoritos enable row level security;
alter table public.eventos enable row level security;
alter table public.notificaciones enable row level security;
alter table public.auditoria enable row level security;
alter table public.reportes enable row level security;

-- ============================================================
-- 17) LIMPIEZA DE TRIGGERS DUPLICADOS
-- ============================================================

-- Eliminar triggers duplicados que causan notificaciones dobles
DROP TRIGGER IF EXISTS trg_notify_campaign_milestone ON public.campanias;
DROP TRIGGER IF EXISTS trg_notify_campaign_published ON public.campanias;
DROP TRIGGER IF EXISTS trg_notify_followers_campaign_update ON public.campanias;
DROP TRIGGER IF EXISTS trg_notify_new_favorite ON public.favoritos;
DROP TRIGGER IF EXISTS trg_notify_organizacion_status ON public.organizaciones;
DROP TRIGGER IF EXISTS trigger_comentario_created ON public.comentarios;

-- Eliminar funciones asociadas que ya no se usan
DROP FUNCTION IF EXISTS notify_campaign_milestone();
DROP FUNCTION IF EXISTS notify_campaign_published();
DROP FUNCTION IF EXISTS notify_followers_campaign_update();
DROP FUNCTION IF EXISTS notify_new_favorite();
DROP FUNCTION IF EXISTS notify_organizacion_status();
DROP FUNCTION IF EXISTS on_comentario_created();

-- ============================================================
-- 18) CONFIGURACIÓN DE REALTIME
-- ============================================================

-- Habilitar replica identity FULL para que Supabase Realtime funcione correctamente
-- Esto permite que los clientes reciban todos los datos del row cuando hay cambios

ALTER TABLE public.campanias REPLICA IDENTITY FULL;
ALTER TABLE public.donaciones REPLICA IDENTITY FULL;
ALTER TABLE public.organizaciones REPLICA IDENTITY FULL;
ALTER TABLE public.notificaciones REPLICA IDENTITY FULL;
ALTER TABLE public.comentarios REPLICA IDENTITY FULL;
ALTER TABLE public.favoritos REPLICA IDENTITY FULL;

-- Habilitar publicación de eventos de realtime para las tablas principales
-- Nota: Esto se debe configurar también en el Dashboard de Supabase > Database > Replication

-- ════════════════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ════════════════════════════════════════════════════════════════════════════
