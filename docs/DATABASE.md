# Database Schema — Chaku Pet Health Tracker

> Engine: PostgreSQL (Supabase)
> All tables have RLS enabled. Access is controlled by two helpers:
> - `has_pet_access(pet_id)` — true if the caller owns/views the pet, or is admin
> - `is_admin()` — true if `profiles.role = 'admin'`

---

## Entity Relationship Overview

```
auth.users (Supabase built-in)
    │
    └── profiles (1:1)
            │
            └── pet_members (M:M) ──────────────── pets
                                                     │
                    ┌────────────────────────────────┼─────────────────────────┐
                    │                                │                         │
               vet_visits                     vaccinations              lab_tests
                    │                                │                    │        │
          ┌─────────┴──────┐              [→vet_visit_id]         lab_results  lab_interpretations
          │                │
      diagnoses         treatments
          │
      treatments (also linked directly to pet_id)

pets ──── diet_entries ──── diet_analyses (AI)
     ──── allergies
     ──── insurance_policies
     ──── attachments (polymorphic: links to any entity)

profiles ──── reminders (per user + pet)
         ──── notifications (per user)

menu_items (self-referential: parent_id → menu_items.id)
```

---

## Table Reference

### `profiles`
Extends `auth.users`. Created automatically on first sign-in via trigger.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK → auth.users(id) CASCADE | Matches Supabase Auth user ID |
| `full_name` | text | | Display name |
| `avatar_url` | text | | Profile picture URL |
| `country` | text | NOT NULL DEFAULT 'CA' | ISO country code |
| `locale` | text | NOT NULL DEFAULT 'en' | UI language: `'en'` \| `'es'` \| … |
| `timezone` | text | NOT NULL DEFAULT 'America/Toronto' | IANA timezone |
| `role` | text | NOT NULL DEFAULT 'owner' CHECK IN ('owner','admin') | App-level role |
| `notification_email` | text | | Overrides auth email for alerts |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**RLS:** User reads/updates own row. Admin reads all.

---

### `pets`
Core pet profile. Soft-deleted via `deleted_at`.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK DEFAULT gen_random_uuid() | |
| `name` | text | NOT NULL | Pet's name |
| `species` | text | NOT NULL CHECK IN ('dog','cat','bird','rabbit','reptile','other') | |
| `breed` | text | | Breed or mix |
| `birth_year` | smallint | | Year of birth |
| `birth_month` | smallint | CHECK 1–12 | Month of birth (optional) |
| `sex` | text | CHECK IN ('male','female','unknown') | |
| `weight_kg` | numeric(6,2) | | Current weight |
| `height_cm` | numeric(6,2) | | Height at withers |
| `length_cm` | numeric(6,2) | | Body length |
| `microchip_id` | text | | Microchip number |
| `color` | text | | Coat/feather color |
| `avatar_url` | text | | Pet photo URL |
| `is_deceased` | boolean | NOT NULL DEFAULT false | |
| `deceased_at` | date | | Date of death |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |
| `deleted_at` | timestamptz | | Soft delete timestamp |

**RLS:** `has_pet_access(id)`

---

### `pet_members`
Many-to-many join between `pets` and `profiles`. **Basis for all health record RLS.**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `user_id` | uuid | NOT NULL FK → profiles(id) CASCADE | |
| `role` | text | NOT NULL DEFAULT 'owner' CHECK IN ('owner','viewer') | Access level |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**Unique:** `(pet_id, user_id)`
**Indexes:** `(user_id)`, `(pet_id)`

---

### `menu_items`
Dynamic, role-aware navigation tree. Add a new section with one `INSERT`.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `key` | text | NOT NULL UNIQUE | Stable code identifier (e.g. `'pets'`) |
| `label` | text | NOT NULL | Default English label |
| `path` | text | NOT NULL | Next.js route (e.g. `'/pets'`) |
| `icon` | text | | lucide-react icon name |
| `parent_id` | uuid | FK → menu_items(id) SET NULL | For nested menus |
| `required_role` | text | CHECK IN ('admin') | `NULL` = all users |
| `sort_order` | smallint | NOT NULL DEFAULT 0 | Display order |
| `is_active` | boolean | NOT NULL DEFAULT true | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**Seed (13 rows):** dashboard, pets, vet-visits, lab-tests, vaccinations, diet, treatments, allergies, insurance, insights, notifications + admin (parent) + admin-users, admin-menu (children).
**RLS:** All authenticated users read active items matching their role. Admin manages all.

---

### `vet_visits`
Veterinary visit records. Source of truth for visit-linked data (diagnoses, treatments, labs).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `visit_date` | date | NOT NULL | |
| `vet_name` | text | | Attending veterinarian |
| `clinic_name` | text | | |
| `clinic_address` | text | | |
| `reason` | text | NOT NULL | Primary reason for visit |
| `chief_complaint` | text | | Owner-reported complaint |
| `weight_at_visit_kg` | numeric(6,2) | | Weight snapshot at visit time |
| `temperature_celsius` | numeric(5,2) | | Body temperature |
| `follow_up_date` | date | | Drives follow-up reminder |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |
| `deleted_at` | timestamptz | | Soft delete |

**Indexes:** `(pet_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `diagnoses`
Diagnoses linked to a vet visit or recorded standalone.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `vet_visit_id` | uuid | FK → vet_visits(id) SET NULL | Optional visit link |
| `diagnosis_name` | text | NOT NULL | |
| `icd_code` | text | | ICD-10 / SNOMED code (optional) |
| `severity` | text | CHECK IN ('mild','moderate','severe') | |
| `status` | text | NOT NULL DEFAULT 'active' CHECK IN ('active','resolved','chronic','monitoring') | Lifecycle state |
| `diagnosed_date` | date | | |
| `resolved_date` | date | | Set when status → resolved |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(pet_id)`, `(vet_visit_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `treatments`
Medications and therapies. May be linked to a diagnosis, a vet visit, or both.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `diagnosis_id` | uuid | FK → diagnoses(id) SET NULL | Optional diagnosis link |
| `vet_visit_id` | uuid | FK → vet_visits(id) SET NULL | Optional visit link |
| `treatment_name` | text | NOT NULL | Drug/therapy name |
| `treatment_type` | text | CHECK IN ('medication','therapy','surgery','supplement','other') | |
| `dosage` | text | | e.g. `'10mg'` |
| `frequency` | text | | e.g. `'twice daily'` |
| `route` | text | CHECK IN ('oral','topical','injection','inhaled','other') | Administration route |
| `start_date` | date | | |
| `end_date` | date | | `NULL` if `is_ongoing = true` |
| `is_ongoing` | boolean | NOT NULL DEFAULT false | |
| `prescribing_vet` | text | | |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(pet_id)`, `(diagnosis_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `allergies`
Known or suspected allergens for a pet.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `allergen` | text | NOT NULL | e.g. `'Chicken'`, `'Pollen'` |
| `allergen_type` | text | CHECK IN ('food','environmental','medication','contact','other') | |
| `severity` | text | CHECK IN ('mild','moderate','severe','life_threatening') | |
| `reaction` | text | | Description of observed reaction |
| `discovered_date` | date | | |
| `confirmed` | boolean | NOT NULL DEFAULT false | Confirmed by a vet |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(pet_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `vaccinations`
Vaccine records with due-date tracking for reminders.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `vet_visit_id` | uuid | FK → vet_visits(id) SET NULL | Added via deferred ALTER TABLE |
| `vaccine_name` | text | NOT NULL | e.g. `'Rabies'`, `'DHPP'` |
| `manufacturer` | text | | |
| `lot_number` | text | | |
| `date_given` | date | NOT NULL | |
| `next_due_date` | date | | Drives reminder creation |
| `administered_by` | text | | Vet name |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |
| `deleted_at` | timestamptz | | Soft delete |

**Indexes:** `(pet_id)`, `(next_due_date) WHERE deleted_at IS NULL` (partial — reminder scheduler)
**RLS:** `has_pet_access(pet_id)`

---

### `lab_tests`
A lab test session (one visit to the lab). Contains one or more `lab_results` rows.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `vet_visit_id` | uuid | FK → vet_visits(id) SET NULL | Added via deferred ALTER TABLE |
| `test_date` | date | NOT NULL | |
| `lab_name` | text | | Laboratory name |
| `test_type` | text | CHECK IN ('blood','urine','feces','imaging','other') | |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |
| `deleted_at` | timestamptz | | Soft delete |

**Indexes:** `(pet_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `lab_results`
Individual parameter values within a lab test. Supports numeric and qualitative results.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `lab_test_id` | uuid | NOT NULL FK → lab_tests(id) CASCADE | |
| `panel_name` | text | | e.g. `'Complete Blood Count'` |
| `parameter_name` | text | NOT NULL | e.g. `'WBC'`, `'Glucose'` |
| `value` | text | NOT NULL | Stored as text (handles `'Negative'`, `'3.5'`, etc.) |
| `unit` | text | | e.g. `'K/µL'`, `'mg/dL'` |
| `reference_min` | numeric | | Lower bound of normal range |
| `reference_max` | numeric | | Upper bound of normal range |
| `reference_text` | text | | For qualitative ranges (e.g. `'Negative'`) |
| `flag` | text | CHECK IN ('L','H','LL','HH','normal','abnormal') | Result flag |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(lab_test_id)`
**RLS:** `has_pet_access` via parent `lab_tests.pet_id`

---

### `lab_interpretations`
LLM-generated plain-language summary for a lab test. One-to-one with `lab_tests`.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `lab_test_id` | uuid | NOT NULL UNIQUE FK → lab_tests(id) CASCADE | 1:1 with lab_tests |
| `summary` | text | NOT NULL | LLM plain-language explanation |
| `disclaimer` | text | NOT NULL | Medical disclaimer (always displayed) |
| `model_used` | text | | Model identifier |
| `generated_at` | timestamptz | NOT NULL DEFAULT now() | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**RLS:** `has_pet_access` via parent `lab_tests.pet_id`

---

### `diet_entries`
Current and historical diet entries for a pet. `end_date IS NULL` = currently active.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `food_name` | text | NOT NULL | |
| `brand` | text | | |
| `food_type` | text | CHECK IN ('dry','wet','raw','homemade','supplement','treat','other') | |
| `amount_grams` | numeric(8,2) | | Per serving in grams |
| `frequency` | text | | e.g. `'2x daily'` |
| `calories_per_day` | numeric(8,2) | | Estimated daily calories |
| `start_date` | date | | |
| `end_date` | date | | `NULL` = currently active |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(pet_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `diet_analyses`
LLM-generated diet analysis per pet. Multiple rows are kept as history; use latest by `generated_at`.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `summary` | text | NOT NULL | LLM analysis |
| `recommendations` | text | | Actionable suggestions |
| `model_used` | text | | |
| `generated_at` | timestamptz | NOT NULL DEFAULT now() | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(pet_id, generated_at DESC)`
**RLS:** `has_pet_access(pet_id)`

---

### `insurance_policies`
Pet insurance policies with renewal date tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | |
| `provider_name` | text | NOT NULL | |
| `policy_number` | text | | |
| `plan_name` | text | | |
| `coverage_type` | text | CHECK IN ('accident','accident_illness','comprehensive','wellness') | |
| `start_date` | date | | |
| `end_date` | date | | Drives renewal reminder |
| `premium_amount` | numeric(10,2) | | |
| `premium_currency` | text | NOT NULL DEFAULT 'CAD' | |
| `premium_frequency` | text | CHECK IN ('monthly','annual') | |
| `deductible_amount` | numeric(10,2) | | |
| `status` | text | NOT NULL DEFAULT 'active' CHECK IN ('active','expired','cancelled','pending') | |
| `notes` | text | | |
| `created_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |
| `updated_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(pet_id, status)`, `(end_date) WHERE status = 'active'` (partial)
**RLS:** `has_pet_access(pet_id)`

---

### `attachments`
Polymorphic file storage. Links files (images, documents, voice notes) to any entity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `entity_type` | text | NOT NULL CHECK IN ('pet','vet_visit','lab_test','vaccination','treatment','diagnosis','insurance_policy') | Parent table name |
| `entity_id` | uuid | NOT NULL | Parent row ID |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | Denormalized for RLS (no join needed) |
| `file_name` | text | NOT NULL | Original filename |
| `file_type` | text | CHECK IN ('image','document','voice_note','other') | |
| `mime_type` | text | | e.g. `'image/jpeg'` |
| `storage_path` | text | NOT NULL | Supabase Storage object path |
| `file_size_bytes` | bigint | | |
| `description` | text | | User-provided description |
| `uploaded_by` | uuid | FK → profiles(id) SET NULL | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(entity_type, entity_id)`, `(pet_id)`
**RLS:** `has_pet_access(pet_id)`

---

### `reminders`
Scheduled alerts for important dates (vaccinations, renewals, follow-ups).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `user_id` | uuid | NOT NULL FK → profiles(id) CASCADE | Alert recipient |
| `pet_id` | uuid | NOT NULL FK → pets(id) CASCADE | Related pet |
| `entity_type` | text | CHECK IN ('vaccination','insurance_policy','vet_visit','treatment') | Source entity type |
| `entity_id` | uuid | | Source entity ID |
| `title` | text | NOT NULL | Alert title |
| `message` | text | | Alert body |
| `remind_at` | timestamptz | NOT NULL | When to fire |
| `channels` | text[] | NOT NULL DEFAULT `['in_app']` | `['email','in_app']` |
| `is_sent` | boolean | NOT NULL DEFAULT false | |
| `sent_at` | timestamptz | | |
| `is_dismissed` | boolean | NOT NULL DEFAULT false | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(user_id, remind_at) WHERE is_sent = false AND is_dismissed = false` (partial — scheduler)
**RLS:** `user_id = auth.uid() OR is_admin()`

---

### `notifications`
In-app notification inbox.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | uuid | PK | |
| `user_id` | uuid | NOT NULL FK → profiles(id) CASCADE | |
| `title` | text | NOT NULL | |
| `message` | text | | |
| `type` | text | CHECK IN ('reminder','insight','system') | |
| `entity_type` | text | | Related entity type (optional) |
| `entity_id` | uuid | | Related entity ID (optional) |
| `is_read` | boolean | NOT NULL DEFAULT false | |
| `read_at` | timestamptz | | |
| `created_at` | timestamptz | NOT NULL DEFAULT now() | |

**Indexes:** `(user_id, is_read)`
**RLS:** `user_id = auth.uid() OR is_admin()`

---

## Relationship Summary

```
auth.users ──1:1──► profiles
profiles   ──M:M──► pets           (via pet_members, role = owner|viewer)
pets       ──1:N──► vet_visits
pets       ──1:N──► vaccinations
pets       ──1:N──► lab_tests      ──1:N──► lab_results
                                   ──1:1──► lab_interpretations
pets       ──1:N──► diet_entries
pets       ──1:N──► diet_analyses
pets       ──1:N──► diagnoses      ──1:N──► treatments
pets       ──1:N──► allergies
pets       ──1:N──► insurance_policies
pets       ──1:N──► attachments    (polymorphic: any entity)
profiles   ──1:N──► reminders
profiles   ──1:N──► notifications
menu_items ──1:N──► menu_items     (self-referential: parent_id)

vet_visits ◄── diagnoses    (optional)
vet_visits ◄── treatments   (optional)
vet_visits ◄── lab_tests    (optional, deferred FK)
vet_visits ◄── vaccinations (optional, deferred FK)
diagnoses  ◄── treatments   (optional)
```

---

## Indexes Summary

| Index | Table | Columns | Notes |
|-------|-------|---------|-------|
| pet_members_user_id_idx | pet_members | user_id | |
| pet_members_pet_id_idx | pet_members | pet_id | |
| vet_visits_pet_id_idx | vet_visits | pet_id | |
| diagnoses_pet_id_idx | diagnoses | pet_id | |
| diagnoses_vet_visit_id_idx | diagnoses | vet_visit_id | |
| treatments_pet_id_idx | treatments | pet_id | |
| treatments_diagnosis_id_idx | treatments | diagnosis_id | |
| allergies_pet_id_idx | allergies | pet_id | |
| vaccinations_pet_id_idx | vaccinations | pet_id | |
| vaccinations_next_due_idx | vaccinations | next_due_date | **Partial:** WHERE deleted_at IS NULL |
| lab_tests_pet_id_idx | lab_tests | pet_id | |
| lab_results_lab_test_id_idx | lab_results | lab_test_id | |
| diet_entries_pet_id_idx | diet_entries | pet_id | |
| diet_analyses_pet_id_idx | diet_analyses | pet_id, generated_at DESC | |
| insurance_pet_id_status_idx | insurance_policies | pet_id, status | |
| insurance_end_date_idx | insurance_policies | end_date | **Partial:** WHERE status = 'active' |
| attachments_entity_idx | attachments | entity_type, entity_id | |
| attachments_pet_id_idx | attachments | pet_id | |
| reminders_user_remind_idx | reminders | user_id, remind_at | **Partial:** WHERE is_sent = false AND is_dismissed = false |
| notifications_user_read_idx | notifications | user_id, is_read | |
| menu_items_parent_id_idx | menu_items | parent_id, sort_order | |
