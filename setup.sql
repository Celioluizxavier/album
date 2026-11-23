-- Rode UMA vez em Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade,email text,name text,status text not null default 'pending',is_admin boolean not null default false,created_at timestamptz default now());
create table albums(id uuid primary key default gen_random_uuid(),title text not null,created_at timestamptz default now());
create table media(id uuid primary key default gen_random_uuid(),album_id uuid references albums on delete cascade,path text not null,kind text not null,pos int default 0);
create table access(album_id uuid references albums on delete cascade,user_id uuid references profiles on delete cascade,primary key(album_id,user_id));
create table logs(id bigserial primary key,user_id uuid,email text,event text,detail text,at timestamptz default now());

create function is_admin() returns boolean language sql security definer stable as $$ select coalesce((select is_admin from profiles where id=auth.uid()),false) $$;
create function is_active() returns boolean language sql security definer stable as $$ select coalesce((select status='active' from profiles where id=auth.uid()),false) $$;
create function new_user() returns trigger language plpgsql security definer as $$ begin insert into profiles(id,email,name) values(new.id,new.email,new.raw_user_meta_data->>'name'); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function new_user();

alter table profiles enable row level security; alter table albums enable row level security; alter table media enable row level security; alter table access enable row level security; alter table logs enable row level security;

create policy p1 on profiles for select using(id=auth.uid() or is_admin());
create policy p2 on profiles for update using(is_admin()) with check(is_admin());
create policy a1 on albums for all using(is_admin()) with check(is_admin());
create policy a2 on albums for select using(is_active() and exists(select 1 from access x where x.album_id=albums.id and x.user_id=auth.uid()));
create policy m1 on media for all using(is_admin()) with check(is_admin());
create policy m2 on media for select using(is_active() and exists(select 1 from access x where x.album_id=media.album_id and x.user_id=auth.uid()));
create policy c1 on access for all using(is_admin()) with check(is_admin());
create policy c2 on access for select using(user_id=auth.uid());
create policy l1 on logs for insert with check(user_id=auth.uid());
create policy l2 on logs for select using(is_admin());

insert into storage.buckets(id,name,public) values('media','media',false);
create policy s1 on storage.objects for all using(bucket_id='media' and is_admin()) with check(bucket_id='media' and is_admin());
create policy s2 on storage.objects for select using(bucket_id='media' and is_active() and exists(select 1 from access x where x.user_id=auth.uid() and x.album_id::text=(storage.foldername(name))[1]));

-- Depois de criar SUA conta no site, torne-se admin (troque o e-mail):
-- update profiles set is_admin=true,status='active' where email='seu@email.com';
