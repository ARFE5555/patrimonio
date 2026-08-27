-- ─────────────────────────────────────────────────────────────────────────────
--  BANCARIZACIONES · tabla nueva para Patrimonio (v5.6)
--
--  YA APLICADO en el proyecto FiveNance el 27/08/2026. Se deja versionado acá
--  como referencia y para poder recrear el esquema desde cero.
--
--  Sigue exactamente el mismo patrón que accounts / txns / divisas / prestamos:
--  una fila por operación, con el contenido completo en la columna JSONB `data`,
--  y los permisos resueltos con la función my_role() que ya existe en la base.
--
--    viewer  → solo lectura
--    loader  → lectura y escritura
--    editor  → lectura y escritura
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.bancarizaciones (
  id          text primary key,
  data        jsonb       not null default '{}'::jsonb,
  updated_at  timestamptz not null default now(),
  updated_by  uuid                 default auth.uid()
);

alter table public.bancarizaciones enable row level security;

grant select, insert, update, delete on public.bancarizaciones to anon, authenticated, service_role;

-- Lectura: cualquier rol de la app
drop policy if exists bancarizaciones_read on public.bancarizaciones;
create policy bancarizaciones_read on public.bancarizaciones
  for select to authenticated
  using (my_role() = any (array['viewer','loader','editor']));

-- Escritura (alta, edición y borrado): loader y editor
drop policy if exists bancarizaciones_write on public.bancarizaciones;
create policy bancarizaciones_write on public.bancarizaciones
  for all to authenticated
  using (my_role() = any (array['loader','editor']))
  with check (my_role() = any (array['loader','editor']));

-- Realtime: los cambios de un usuario le llegan al resto al instante
alter publication supabase_realtime add table public.bancarizaciones;
