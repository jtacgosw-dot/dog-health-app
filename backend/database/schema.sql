create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  apple_sub text unique not null,     -- 'sub' from Apple identity token
  created_at timestamptz default now()
);

create table if not exists entitlements (
  user_id uuid references users(id) on delete cascade,
  is_active boolean not null default false,
  product_id text,                    -- pup_monthly / pup_annual
  renews_at timestamptz,
  updated_at timestamptz default now(),
  primary key (user_id)
);

create index if not exists idx_users_apple_sub on users(apple_sub);
create index if not exists idx_entitlements_user_id on entitlements(user_id);
create index if not exists idx_entitlements_is_active on entitlements(is_active);
