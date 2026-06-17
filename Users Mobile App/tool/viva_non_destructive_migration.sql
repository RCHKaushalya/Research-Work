-- Viva-safe Supabase migration.
-- This does not drop data. Run in Supabase SQL Editor before the viva seed
-- if volunteers, pending requests, or portfolio photos are missing.

create table if not exists public.volunteers (
    id uuid not null unique default gen_random_uuid(),
    volunteer_id text primary key,
    full_name text not null,
    password text not null,
    district text,
    language text default 'si',
    active boolean default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.pending_user_registrations (
    id uuid primary key default gen_random_uuid(),
    phone text,
    nic text,
    pin text,
    first_name text,
    last_name text,
    district text,
    ds_area text,
    language text default 'si',
    job_category_ids text[] default '{}',
    skill_ids text[] default '{}',
    status text not null default 'pending',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.pending_job_posts (
    id uuid primary key default gen_random_uuid(),
    employer_nic text,
    employer_name text,
    employer_phone text,
    job_title text,
    job_description text,
    district text,
    ds_area text,
    category text,
    required_skills text,
    payment text,
    language text default 'si',
    status text not null default 'pending',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.users
add column if not exists portfolio_photo_urls text[] default '{}';

create index if not exists idx_volunteers_active on public.volunteers (active);
create index if not exists idx_pending_user_registrations_status
on public.pending_user_registrations (status);
create index if not exists idx_pending_job_posts_status
on public.pending_job_posts (status);

alter table public.volunteers disable row level security;
alter table public.pending_user_registrations disable row level security;
alter table public.pending_job_posts disable row level security;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'profile-photos',
    'profile-photos',
    true,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public profile photo read" on storage.objects;
create policy "Public profile photo read"
on storage.objects for select
to public
using (bucket_id = 'profile-photos');

drop policy if exists "Public profile photo upload" on storage.objects;
create policy "Public profile photo upload"
on storage.objects for insert
to public
with check (bucket_id = 'profile-photos');

drop policy if exists "Public profile photo update" on storage.objects;
create policy "Public profile photo update"
on storage.objects for update
to public
using (bucket_id = 'profile-photos')
with check (bucket_id = 'profile-photos');
