-- ============================================================================
-- RPC consolidado para métricas del dashboard admin.
-- Reemplaza los loops O(N) en Dart por agregados SQL en un solo round-trip.
-- Solo lo puede ejecutar un admin (chequeo con is_admin(auth.uid())).
-- ============================================================================

create or replace function public.get_admin_dashboard_metrics()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  result jsonb;
  start_of_month timestamptz := date_trunc('month', now());
  start_of_last_month timestamptz := date_trunc('month', now() - interval '1 month');
begin
  if not public.is_admin(auth.uid()) then
    raise exception 'No autorizado: solo administradores.';
  end if;

  with
    req_stats as (
      select
        count(*) filter (where estado = 'pendiente') as pending,
        count(*) filter (where estado = 'aprobada') as approved,
        count(*) filter (where estado in ('aprobada','rechazada')) as processed,
        coalesce(
          avg(extract(epoch from (updated_at - created_at)) / 3600.0)
            filter (where estado <> 'pendiente' and updated_at > created_at),
          24.0
        ) as avg_response_hours
      from public.solicitudes
    ),
    don_stats as (
      select
        count(*) filter (where estado = 'pendiente') as pending,
        count(*) filter (where estado = 'aprobada' and created_at >= start_of_month) as this_month,
        count(*) filter (where estado = 'aprobada' and created_at >= start_of_last_month and created_at < start_of_month) as last_month,
        coalesce(sum(monto) filter (where estado = 'aprobada'), 0)::numeric as total_approved,
        coalesce(avg(monto) filter (where estado = 'aprobada'), 0)::numeric as avg_amount
      from public.donaciones
    ),
    donor_stats as (
      select
        count(distinct user_id) filter (where user_id is not null) as total_donors,
        count(distinct user_id) filter (
          where user_id is not null and user_id in (
            select user_id from public.donaciones
            where user_id is not null
            group by user_id
            having count(*) > 1
          )
        ) as repeat_donors
      from public.donaciones
      where estado = 'aprobada'
    ),
    org_stats as (
      select count(*) filter (where estado = 'pendiente') as pending
      from public.organizaciones
    ),
    camp_stats as (
      select
        count(*) filter (where estado = 'activa') as active,
        count(*) filter (
          where estado = 'finalizada' and updated_at >= start_of_month
        ) as completed_this_month
      from public.campanias
    ),
    top_category as (
      select cat.nombre as nombre
      from public.campanias c
      join public.categorias cat on cat.id = c.categoria_id
      where c.estado = 'finalizada'
      group by cat.nombre
      order by count(*) desc
      limit 1
    )
  select jsonb_build_object(
    'pendingRequests', (select pending from req_stats),
    'pendingDonations', (select pending from don_stats),
    'pendingOrganizations', (select pending from org_stats),
    'activeCampaigns', (select active from camp_stats),
    'totalApprovedAmount', (select total_approved from don_stats),
    'approvalRate', case
      when (select processed from req_stats) > 0
        then ((select approved from req_stats)::numeric / (select processed from req_stats) * 100)
      else 0
    end,
    'avgResponseTimeHours', (select avg_response_hours from req_stats),
    'totalDonors', (select total_donors from donor_stats),
    'repeatDonorsPercentage', case
      when (select total_donors from donor_stats) > 0
        then ((select repeat_donors from donor_stats)::numeric / (select total_donors from donor_stats) * 100)
      else 0
    end,
    'campaignsCompletedThisMonth', (select completed_this_month from camp_stats),
    'donationsThisMonth', (select this_month from don_stats),
    'donationsLastMonth', (select last_month from don_stats),
    'donationGrowthRate', case
      when (select last_month from don_stats) > 0 then
        (((select this_month from don_stats) - (select last_month from don_stats))::numeric
          / (select last_month from don_stats) * 100)
      when (select this_month from don_stats) > 0 then 100.0
      else 0
    end,
    'avgDonationAmount', (select avg_amount from don_stats),
    'topCampaignCategory', coalesce((select nombre from top_category), 'N/A')
  ) into result;

  return result;
end $$;

grant execute on function public.get_admin_dashboard_metrics() to authenticated;
revoke execute on function public.get_admin_dashboard_metrics() from anon;
