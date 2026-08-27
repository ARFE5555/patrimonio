-- ─────────────────────────────────────────────────────────────────────────────
--  BANCARIZACIONES · tabla nueva para Patrimonio (v5.6)
--
--  Correr una sola vez en Supabase → SQL Editor.
--  Sigue el mismo patrón que el resto de las colecciones de la app:
--  una fila por operación, con el contenido completo en la columna JSONB `data`.
--
--  Permisos (igual que las demás tablas):
--    viewer  → solo lectura
--    loader  → lectura, alta y edición
--    editor  → todo, incluido borrar
--
--  NOTA: si tus tablas existentes usan `uuid` en vez de `text` para el id,
--  cambiá el tipo de la columna `id` acá abajo. La app genera ids de texto
--  (ej. "m2x3k1a9b"), así que `text` es lo que corresponde en una instalación
--  estándar de esta app.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.bancarizaciones (
  id          text primary key,
  data        jsonb       not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table public.bancarizaciones enable row level security;

-- Lectura: cualquier usuario autenticado
drop policy if exists banc_select on public.bancarizaciones;
create policy banc_select on public.bancarizaciones
  for select to authenticated
  using (true);

-- Alta: loader y editor
drop policy if exists banc_insert on public.bancarizaciones;
create policy banc_insert on public.bancarizaciones
  for insert to authenticated
  with check (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('loader', 'editor')
  ));

-- Edición: loader y editor
drop policy if exists banc_update on public.bancarizaciones;
create policy banc_update on public.bancarizaciones
  for update to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('loader', 'editor')
  ))
  with check (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('loader', 'editor')
  ));

-- Borrado: solo editor
drop policy if exists banc_delete on public.bancarizaciones;
create policy banc_delete on public.bancarizaciones
  for delete to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'editor'
  ));

-- Realtime: para que los cambios de un usuario le lleguen al resto al instante
alter publication supabase_realtime add table public.bancarizaciones;
