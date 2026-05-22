-- ============================================================
-- Chaku — Pet Health Tracker
-- Database schema for Supabase (PostgreSQL)
-- Run in Supabase SQL Editor → New query
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. IDENTITY & ACCESS
-- ─────────────────────────────────────────────

create table if not exists profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  full_name           text,
  avatar_url          text,
  country             text        not null default 'CA',
  locale              text        not null default 'en',  -- i18n: 'en' | 'es' | ...
  timezone            text        not null default 'America/Toronto',
  role                text        not null default 'owner'
                                  check (role in ('owner', 'admin')),
  notification_email  text,       -- overrides auth email for alerts
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table profiles is
  'Extends auth.users. One row per authenticated user.';

-- ─────────────────────────────────────────────
-- 2. PETS
-- ─────────────────────────────────────────────

create table if not exists pets (
  id              uuid        primary key default gen_random_uuid(),
  name            text        not null,
  species         text        not null
                              check (species in ('dog','cat','bird','rabbit','reptile','other')),
  breed           text,
  birth_year      smallint,
  birth_month     smallint    check (birth_month between 1 and 12),
  sex             text        check (sex in ('male','female','unknown')),
  weight_kg       numeric(6,2),
  height_cm       numeric(6,2),
  length_cm       numeric(6,2),
  microchip_id    text,
  color           text,
  avatar_url      text,
  is_deceased     boolean     not null default false,
  deceased_at     date,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz                            -- soft delete
);

comment on table pets is
  'Core pet profile. Soft-deleted via deleted_at.';

-- ─────────────────────────────────────────────
-- 3. PET MEMBERS (pet ↔ user many-to-many)
-- ─────────────────────────────────────────────

create table if not exists pet_members (
  id          uuid        primary key default gen_random_uuid(),
  pet_id      uuid        not null references pets(id)     on delete cascade,
  user_id     uuid        not null references profiles(id) on delete cascade,
  role        text        not null default 'owner'
                          check (role in ('owner','viewer')),
  created_at  timestamptz not null default now(),
  unique (pet_id, user_id)
);

comment on table pet_members is
  'Controls which users can access which pets. Basis for all RLS policies.';

-- ─────────────────────────────────────────────
-- 4. MENU ITEMS (dynamic, role-aware navigation)
-- ─────────────────────────────────────────────

create table if not exists menu_items (
  id              uuid        primary key default gen_random_uuid(),
  key             text        not null unique,  -- stable identifier used in code
  label           text        not null,         -- default English label
  path            text        not null,         -- Next.js route, e.g. '/pets'
  icon            text,                         -- lucide-react icon name
  parent_id       uuid        references menu_items(id) on delete set null,
  required_role   text        check (required_role in ('admin')),  -- null = all users
  sort_order      smallint    not null default 0,
  is_active       boolean     not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table menu_items is
  'Dynamic navigation config. Add a new section with one INSERT — no code change.';

-- ─────────────────────────────────────────────
-- 5. VET VISITS
-- ─────────────────────────────────────────────

create table if not exists vet_visits (
  id                  uuid        primary key default gen_random_uuid(),
  pet_id              uuid        not null references pets(id) on delete cascade,
  visit_date          date        not null,
  vet_name            text,
  clinic_name         text,
  clinic_address      text,
  reason              text        not null,
  chief_complaint     text,
  weight_at_visit_kg  numeric(6,2),
  temperature_celsius numeric(5,2),
  follow_up_date      date,
  notes               text,
  created_by          uuid        references profiles(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

-- ─────────────────────────────────────────────
-- 6. DIAGNOSES
-- ─────────────────────────────────────────────

create table if not exists diagnoses (
  id              uuid        primary key default gen_random_uuid(),
  pet_id          uuid        not null references pets(id)       on delete cascade,
  vet_visit_id    uuid        references vet_visits(id)          on delete set null,
  diagnosis_name  text        not null,
  icd_code        text,       -- optional ICD/SNOMED for interoperability
  severity        text        check (severity in ('mild','moderate','severe')),
  status          text        not null default 'active'
                              check (status in ('active','resolved','chronic','monitoring')),
  diagnosed_date  date,
  resolved_date   date,
  notes           text,
  created_by      uuid        references profiles(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 7. TREATMENTS
-- ─────────────────────────────────────────────

create table if not exists treatments (
  id               uuid        primary key default gen_random_uuid(),
  pet_id           uuid        not null references pets(id)       on delete cascade,
  diagnosis_id     uuid        references diagnoses(id)           on delete set null,
  vet_visit_id     uuid        references vet_visits(id)          on delete set null,
  treatment_name   text        not null,
  treatment_type   text        check (treatment_type in
                                ('medication','therapy','surgery','supplement','other')),
  dosage           text,
  frequency        text,
  route            text        check (route in ('oral','topical','injection','inhaled','other')),
  start_date       date,
  end_date         date,
  is_ongoing       boolean     not null default false,
  prescribing_vet  text,
  notes            text,
  created_by       uuid        references profiles(id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 8. ALLERGIES
-- ─────────────────────────────────────────────

create table if not exists allergies (
  id               uuid        primary key default gen_random_uuid(),
  pet_id           uuid        not null references pets(id) on delete cascade,
  allergen         text        not null,
  allergen_type    text        check (allergen_type in
                                ('food','environmental','medication','contact','other')),
  severity         text        check (severity in
                                ('mild','moderate','severe','life_threatening')),
  reaction         text,       -- description of observed reaction
  discovered_date  date,
  confirmed        boolean     not null default false,  -- confirmed by a vet
  notes            text,
  created_by       uuid        references profiles(id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 9. VACCINATIONS
-- ─────────────────────────────────────────────

create table if not exists vaccinations (
  id              uuid        primary key default gen_random_uuid(),
  pet_id          uuid        not null references pets(id) on delete cascade,
  vaccine_name    text        not null,
  manufacturer    text,
  lot_number      text,
  date_given      date        not null,
  next_due_date   date,       -- drives reminder creation
  administered_by text,
  notes           text,
  created_by      uuid        references profiles(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

-- ─────────────────────────────────────────────
-- 10. LAB TESTS
-- ─────────────────────────────────────────────

create table if not exists lab_tests (
  id          uuid        primary key default gen_random_uuid(),
  pet_id      uuid        not null references pets(id) on delete cascade,
  test_date   date        not null,
  lab_name    text,
  test_type   text        check (test_type in ('blood','urine','feces','imaging','other')),
  notes       text,
  created_by  uuid        references profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ─────────────────────────────────────────────
-- 11. LAB RESULTS
-- ─────────────────────────────────────────────

create table if not exists lab_results (
  id               uuid        primary key default gen_random_uuid(),
  lab_test_id      uuid        not null references lab_tests(id) on delete cascade,
  panel_name       text,                         -- e.g. 'Complete Blood Count'
  parameter_name   text        not null,         -- e.g. 'WBC', 'Glucose'
  value            text        not null,         -- text to handle qualitative + numeric
  unit             text,
  reference_min    numeric,
  reference_max    numeric,
  reference_text   text,                         -- e.g. 'Negative' for qualitative
  flag             text        check (flag in ('L','H','LL','HH','normal','abnormal')),
  created_at       timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 12. DIET ENTRIES
-- ─────────────────────────────────────────────

create table if not exists diet_entries (
  id                  uuid        primary key default gen_random_uuid(),
  pet_id              uuid        not null references pets(id) on delete cascade,
  food_name           text        not null,
  brand               text,
  food_type           text        check (food_type in
                                    ('dry','wet','raw','homemade','supplement','treat','other')),
  amount_grams        numeric(8,2),
  frequency           text,                         -- e.g. '2x daily'
  calories_per_day    numeric(8,2),
  start_date          date,
  end_date            date,                         -- null = currently active
  notes               text,
  created_by          uuid        references profiles(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 13. AI LAB INTERPRETATIONS
-- ─────────────────────────────────────────────

create table if not exists lab_interpretations (
  id              uuid        primary key default gen_random_uuid(),
  lab_test_id     uuid        not null unique references lab_tests(id) on delete cascade,
  summary         text        not null,   -- LLM plain-language summary
  disclaimer      text        not null,   -- medical disclaimer (always shown)
  model_used      text,
  generated_at    timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 14. AI DIET ANALYSES
-- ─────────────────────────────────────────────

create table if not exists diet_analyses (
  id                uuid        primary key default gen_random_uuid(),
  pet_id            uuid        not null references pets(id) on delete cascade,
  summary           text        not null,
  recommendations   text,
  model_used        text,
  generated_at      timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 15. INSURANCE POLICIES
-- ─────────────────────────────────────────────

create table if not exists insurance_policies (
  id                  uuid        primary key default gen_random_uuid(),
  pet_id              uuid        not null references pets(id) on delete cascade,
  provider_name       text        not null,
  policy_number       text,
  plan_name           text,
  coverage_type       text        check (coverage_type in
                                    ('accident','accident_illness','comprehensive','wellness')),
  start_date          date,
  end_date            date,       -- drives renewal reminder
  premium_amount      numeric(10,2),
  premium_currency    text        not null default 'CAD',
  premium_frequency   text        check (premium_frequency in ('monthly','annual')),
  deductible_amount   numeric(10,2),
  status              text        not null default 'active'
                                  check (status in ('active','expired','cancelled','pending')),
  notes               text,
  created_by          uuid        references profiles(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 16. ATTACHMENTS (polymorphic)
-- ─────────────────────────────────────────────

create table if not exists attachments (
  id              uuid        primary key default gen_random_uuid(),
  entity_type     text        not null
                              check (entity_type in (
                                'pet','vet_visit','lab_test','vaccination',
                                'treatment','diagnosis','insurance_policy'
                              )),
  entity_id       uuid        not null,
  -- pet_id denormalized so RLS can check ownership without extra joins
  pet_id          uuid        not null references pets(id) on delete cascade,
  file_name       text        not null,
  file_type       text        check (file_type in ('image','document','voice_note','other')),
  mime_type       text,
  storage_path    text        not null,   -- Supabase Storage object path
  file_size_bytes bigint,
  description     text,
  uploaded_by     uuid        references profiles(id) on delete set null,
  created_at      timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 17. REMINDERS
-- ─────────────────────────────────────────────

create table if not exists reminders (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references profiles(id) on delete cascade,
  pet_id          uuid        not null references pets(id)     on delete cascade,
  entity_type     text        check (entity_type in
                                ('vaccination','insurance_policy','vet_visit','treatment')),
  entity_id       uuid,
  title           text        not null,
  message         text,
  remind_at       timestamptz not null,
  channels        text[]      not null default array['in_app'], -- ['email','in_app']
  is_sent         boolean     not null default false,
  sent_at         timestamptz,
  is_dismissed    boolean     not null default false,
  created_at      timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 18. NOTIFICATIONS (in-app inbox)
-- ─────────────────────────────────────────────

create table if not exists notifications (
  id              uuid        primary key default gen_random_uuid(),
  user_id         uuid        not null references profiles(id) on delete cascade,
  title           text        not null,
  message         text,
  type            text        check (type in ('reminder','insight','system')),
  entity_type     text,
  entity_id       uuid,
  is_read         boolean     not null default false,
  read_at         timestamptz,
  created_at      timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- DEFERRED FKs (avoid circular dependency at table creation)
-- ─────────────────────────────────────────────

alter table lab_tests
  add column if not exists vet_visit_id uuid references vet_visits(id) on delete set null;

alter table vaccinations
  add column if not exists vet_visit_id uuid references vet_visits(id) on delete set null;

-- ─────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────

-- pet_members
create index if not exists pet_members_user_id_idx  on pet_members(user_id);
create index if not exists pet_members_pet_id_idx   on pet_members(pet_id);

-- vet_visits
create index if not exists vet_visits_pet_id_idx    on vet_visits(pet_id);

-- diagnoses
create index if not exists diagnoses_pet_id_idx         on diagnoses(pet_id);
create index if not exists diagnoses_vet_visit_id_idx   on diagnoses(vet_visit_id);

-- treatments
create index if not exists treatments_pet_id_idx        on treatments(pet_id);
create index if not exists treatments_diagnosis_id_idx  on treatments(diagnosis_id);

-- allergies
create index if not exists allergies_pet_id_idx         on allergies(pet_id);

-- vaccinations
create index if not exists vaccinations_pet_id_idx      on vaccinations(pet_id);
create index if not exists vaccinations_next_due_idx    on vaccinations(next_due_date)
  where deleted_at is null;  -- only active records for reminder scheduler

-- lab_tests / lab_results
create index if not exists lab_tests_pet_id_idx         on lab_tests(pet_id);
create index if not exists lab_results_lab_test_id_idx  on lab_results(lab_test_id);

-- diet
create index if not exists diet_entries_pet_id_idx      on diet_entries(pet_id);

-- diet_analyses (latest per pet)
create index if not exists diet_analyses_pet_id_idx     on diet_analyses(pet_id, generated_at desc);

-- insurance
create index if not exists insurance_pet_id_status_idx  on insurance_policies(pet_id, status);
create index if not exists insurance_end_date_idx       on insurance_policies(end_date)
  where status = 'active';  -- for renewal alert queries

-- attachments
create index if not exists attachments_entity_idx       on attachments(entity_type, entity_id);
create index if not exists attachments_pet_id_idx       on attachments(pet_id);

-- reminders
create index if not exists reminders_user_remind_idx    on reminders(user_id, remind_at)
  where is_sent = false and is_dismissed = false;

-- notifications
create index if not exists notifications_user_read_idx  on notifications(user_id, is_read);

-- menu_items
create index if not exists menu_items_parent_id_idx     on menu_items(parent_id, sort_order);

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ─────────────────────────────────────────────

alter table profiles           enable row level security;
alter table pets               enable row level security;
alter table pet_members        enable row level security;
alter table menu_items         enable row level security;
alter table vet_visits         enable row level security;
alter table diagnoses          enable row level security;
alter table treatments         enable row level security;
alter table allergies          enable row level security;
alter table vaccinations       enable row level security;
alter table lab_tests          enable row level security;
alter table lab_results        enable row level security;
alter table diet_entries       enable row level security;
alter table lab_interpretations enable row level security;
alter table diet_analyses      enable row level security;
alter table insurance_policies enable row level security;
alter table attachments        enable row level security;
alter table reminders          enable row level security;
alter table notifications      enable row level security;

-- Helper: is the calling user an admin?
create or replace function is_admin()
returns boolean language sql security definer as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- Helper: does the calling user have access to this pet?
create or replace function has_pet_access(p_pet_id uuid)
returns boolean language sql security definer as $$
  select exists (
    select 1 from pet_members
    where pet_id = p_pet_id and user_id = auth.uid()
  ) or is_admin();
$$;

-- profiles
create policy "users read own profile"
  on profiles for select using (id = auth.uid() or is_admin());

create policy "users update own profile"
  on profiles for update using (id = auth.uid());

create policy "users insert own profile"
  on profiles for insert with check (id = auth.uid());

-- pets
create policy "pet member access"
  on pets for all using (has_pet_access(id));

create policy "insert pets for authenticated"
  on pets for insert with check (auth.uid() is not null);

-- pet_members
create policy "member reads own memberships"
  on pet_members for select using (user_id = auth.uid() or is_admin());

create policy "owner manages memberships"
  on pet_members for all using (
    user_id = auth.uid()
    or exists (
      select 1 from pet_members pm
      where pm.pet_id = pet_members.pet_id
        and pm.user_id = auth.uid()
        and pm.role = 'owner'
    )
    or is_admin()
  );

-- menu_items (read-only for all authenticated users, admin manages)
create policy "authenticated users read active menu"
  on menu_items for select using (
    auth.uid() is not null
    and is_active = true
    and (required_role is null or is_admin())
  );

create policy "admin manages menu"
  on menu_items for all using (is_admin());

-- Health record tables — uniform pattern via has_pet_access()
create policy "pet access" on vet_visits        for all using (has_pet_access(pet_id));
create policy "pet access" on diagnoses         for all using (has_pet_access(pet_id));
create policy "pet access" on treatments        for all using (has_pet_access(pet_id));
create policy "pet access" on allergies         for all using (has_pet_access(pet_id));
create policy "pet access" on vaccinations      for all using (has_pet_access(pet_id));
create policy "pet access" on lab_tests         for all using (has_pet_access(pet_id));
create policy "pet access" on diet_entries      for all using (has_pet_access(pet_id));
create policy "pet access" on lab_interpretations for all using (
  has_pet_access((select pet_id from lab_tests where id = lab_test_id))
);
create policy "pet access" on diet_analyses     for all using (has_pet_access(pet_id));
create policy "pet access" on insurance_policies for all using (has_pet_access(pet_id));
create policy "pet access" on attachments       for all using (has_pet_access(pet_id));
create policy "pet access" on lab_results       for all using (
  has_pet_access((select pet_id from lab_tests where id = lab_test_id))
);

-- reminders and notifications scoped to the user
create policy "own reminders"     on reminders      for all using (user_id = auth.uid() or is_admin());
create policy "own notifications" on notifications  for all using (user_id = auth.uid() or is_admin());

-- ─────────────────────────────────────────────
-- SEED: default menu items
-- ─────────────────────────────────────────────

insert into menu_items (key, label, path, icon, sort_order) values
  ('dashboard',    'Dashboard',     '/',               'LayoutDashboard', 0),
  ('pets',         'My Pets',       '/pets',           'PawPrint',        1),
  ('vet-visits',   'Vet Visits',    '/vet-visits',     'Stethoscope',     2),
  ('lab-tests',    'Lab Tests',     '/lab-tests',      'FlaskConical',    3),
  ('vaccinations', 'Vaccinations',  '/vaccinations',   'Syringe',         4),
  ('diet',         'Diet',          '/diet',           'UtensilsCrossed', 5),
  ('treatments',   'Treatments',    '/treatments',     'Pill',            6),
  ('allergies',    'Allergies',     '/allergies',      'AlertTriangle',   7),
  ('insurance',    'Insurance',     '/insurance',      'ShieldCheck',     8),
  ('insights',     'Insights',      '/insights',       'BarChart3',       9),
  ('notifications','Notifications', '/notifications',  'Bell',            10)
on conflict (key) do nothing;

-- Admin section (parent + children)
insert into menu_items (key, label, path, icon, sort_order, required_role) values
  ('admin', 'Admin', '/admin', 'Settings', 99, 'admin')
on conflict (key) do nothing;

insert into menu_items (key, label, path, icon, sort_order, required_role, parent_id)
select
  'admin-users', 'Users', '/admin/users', 'Users', 0, 'admin', id
from menu_items where key = 'admin'
on conflict (key) do nothing;

insert into menu_items (key, label, path, icon, sort_order, required_role, parent_id)
select
  'admin-menu', 'Menu Config', '/admin/menu', 'Menu', 1, 'admin', id
from menu_items where key = 'admin'
on conflict (key) do nothing;
