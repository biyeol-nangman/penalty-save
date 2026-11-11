-- 패널티킥 세이브 순위표용 테이블과 규칙.
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여 넣고 Run 하세요. 여러 번 실행해도 됩니다.

create table if not exists public.scores (
  player_id   uuid primary key,                       -- 브라우저마다 자동으로 만들어지는 익명 ID
  name        text        not null check (char_length(name) between 1 and 12),
  team        text        not null check (char_length(team) between 1 and 8),
  saves       integer     not null check (saves between 0 and 500),
  kmh         integer     not null check (kmh between 0 and 300),
  achieved_at timestamptz not null default now()      -- 최고 기록을 세운 시각 (동점이면 먼저 달성한 사람이 위)
);

create index if not exists scores_rank_idx on public.scores (saves desc, achieved_at asc);

-- 행 단위 보안: 읽기만 모두에게 열고, 직접 쓰기/수정/삭제 규칙은 만들지 않습니다(= 막힘).
alter table public.scores enable row level security;

drop policy if exists "scores are readable by everyone" on public.scores;
create policy "scores are readable by everyone"
  on public.scores for select
  to anon, authenticated
  using (true);

-- 기록은 이 함수로만 남길 수 있습니다. 값 범위를 검사하고, 기존 최고 기록보다 높을 때만 점수를 갱신합니다.
create or replace function public.submit_score(
  p_player uuid,
  p_name   text,
  p_team   text,
  p_saves  integer,
  p_kmh    integer
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := left(btrim(coalesce(p_name, '')), 12);
begin
  if p_player is null then raise exception 'invalid player'; end if;
  if p_saves is null or p_saves < 0 or p_saves > 500 then raise exception 'invalid saves'; end if;
  if p_kmh   is null or p_kmh   < 0 or p_kmh   > 300 then raise exception 'invalid speed'; end if;
  if p_team  is null or char_length(p_team) not between 1 and 8 then raise exception 'invalid team'; end if;
  if v_name = '' then v_name := '무명 키퍼'; end if;

  insert into public.scores as s (player_id, name, team, saves, kmh)
  values (p_player, v_name, p_team, p_saves, p_kmh)
  on conflict (player_id) do update
    set name        = excluded.name,
        team        = excluded.team,
        achieved_at = case when excluded.saves > s.saves then now() else s.achieved_at end,
        saves       = greatest(s.saves, excluded.saves),
        kmh         = greatest(s.kmh,   excluded.kmh);
end;
$$;

revoke all on function public.submit_score(uuid, text, text, integer, integer) from public;
grant execute on function public.submit_score(uuid, text, text, integer, integer) to anon, authenticated;
