-- Workforce Platform Supabase schema
-- Target tables from the report: users, jobs, applications, messages, reviews.

-- Clean up legacy tables to ensure schema is fully updated
drop table if exists public.reviews cascade;
drop table if exists public.messages cascade;
drop table if exists public.applications cascade;
drop table if exists public.jobs cascade;
drop table if exists public.pending_job_posts cascade;
drop table if exists public.pending_user_registrations cascade;
drop table if exists public.users cascade;
drop table if exists public.volunteers cascade;
drop table if exists public.sms_messages cascade;

create table if not exists public.users (
    id uuid not null unique default gen_random_uuid(),
    nic text primary key,
    first_name text not null,
    last_name text not null,
    phone text,
    password_hash text,
    district text,
    ds_area text,
    language text default 'si',
    verified boolean default false,
    profile_photo_url text,
    portfolio_photo_urls text[] default '{}',
    rating numeric(3,2) default 0,
    completed_jobs_count integer default 0,
    abandoned_jobs_count integer default 0,
    posted_jobs_count integer default 0,
    applied_jobs_count integer default 0,
    removed_jobs_count integer default 0,
    availability_status text default 'available',
    is_blocked integer default 0,
    job_category_ids text[] default '{}',
    skill_ids text[] default '{}',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

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

create table if not exists public.jobs (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text not null,
    employer_nic text references public.users(nic) on delete set null,
    category text,
    location text,
    status text not null default 'open',
    required_skills text[] default '{}',
    applied_worker_ids text[] default '{}',
    accepted_worker_ids text[] default '{}',
    payments jsonb default '[]'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.applications (
    id uuid primary key default gen_random_uuid(),
    job_id uuid not null references public.jobs(id) on delete cascade,
    worker_nic text not null references public.users(nic) on delete cascade,
    status text not null default 'applied',
    applied_at timestamptz not null default now(),
    unique (job_id, worker_nic)
);

create table if not exists public.messages (
    id uuid primary key default gen_random_uuid(),
    sender_nic text references public.users(nic) on delete set null,
    receiver_nic text references public.users(nic) on delete set null,
    community_channel text,
    content text not null,
    created_at timestamptz not null default now()
);

create table if not exists public.reviews (
    id uuid primary key default gen_random_uuid(),
    reviewer_nic text references public.users(nic) on delete set null,
    worker_nic text not null references public.users(nic) on delete cascade,
    rating numeric(3,2) not null,
    comment text,
    created_at timestamptz not null default now()
);

create table if not exists public.sms_messages (
    id text primary key,
    phone_number text not null,
    message text not null,
    direction text not null,
    status text not null,
    created_at timestamptz not null,
    sent_at timestamptz
);

create index if not exists idx_users_nic on public.users (nic);
create index if not exists idx_volunteers_active on public.volunteers (active);
create index if not exists idx_pending_user_registrations_status on public.pending_user_registrations (status);
create index if not exists idx_pending_job_posts_status on public.pending_job_posts (status);
create index if not exists idx_jobs_status on public.jobs (status);
create index if not exists idx_jobs_location on public.jobs (location);
create index if not exists idx_applications_worker_nic on public.applications (worker_nic);
create index if not exists idx_messages_receiver_nic on public.messages (receiver_nic);
create index if not exists idx_reviews_worker_nic on public.reviews (worker_nic);
create index if not exists idx_sms_messages_direction_status on public.sms_messages (direction, status);

-- Public profile-photo storage for the mobile app.
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

-- Disable Row Level Security on all tables to allow public REST API access without active session policies (standard for the prototype)
alter table public.users disable row level security;
alter table public.volunteers disable row level security;
alter table public.pending_user_registrations disable row level security;
alter table public.pending_job_posts disable row level security;
alter table public.jobs disable row level security;
alter table public.applications disable row level security;
alter table public.messages disable row level security;
alter table public.reviews disable row level security;
alter table public.sms_messages disable row level security;

-- ─── Chat tables (in-app messaging) ──────────────────────────────────────────

drop table if exists public.chat_messages cascade;
drop table if exists public.chats cascade;

create table if not exists public.chats (
    id text primary key,                      -- e.g. 'direct_NIC1_NIC2' or 'group_jobId'
    job_id uuid references public.jobs(id) on delete set null,
    participant_ids text[] not null default '{}',
    type text not null default 'direct',      -- 'direct' | 'group' | 'community'
    title text,
    last_message text,
    last_message_time timestamptz,
    created_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
    id uuid primary key default gen_random_uuid(),
    chat_id text not null references public.chats(id) on delete cascade,
    sender_id text not null,                  -- NIC of the sender
    text text not null,
    created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_chat_id on public.chat_messages (chat_id, created_at desc);
create index if not exists idx_chats_participant_ids on public.chats using gin (participant_ids);

alter table public.chats disable row level security;
alter table public.chat_messages disable row level security;
