# Ranking Global Online (Supabase + Fallback Local)

Documentação da arquitetura de backend e banco de dados do **Sistema de Rank Global / Speedrun** introduzido na **Issue #9 (`v1.3.0`)**.

---

## 1. Projeto Supabase e Modelo de Segurança

* **Project Ref:** `tgwoptupssqptvpmuija`
* **Endpoint REST (Data API):** `https://tgwoptupssqptvpmuija.supabase.co/rest/v1/speedrun_ranks`
* **Autenticação no Cliente WebGL (`autoload/LeaderboardService.gd`):**
  * Utiliza **apenas** a `SUPABASE_URL` pública e a `Publishable Key` pública (`sb_publishable_...`) enviada no cabeçalho HTTP `apikey`.
  * **Nenhuma** `service_role`, `secret` key ou senha do PostgreSQL existe no código-fonte ou no pacote `.pck` exportado para WebGL.
  * Todas as escritas e leituras são protegidas diretamente no PostgreSQL por **Row Level Security (RLS)**, `GRANT` explícito mínimo e `CHECK constraints`.

---

## 2. Schema SQL, Índices e Políticas RLS

O schema aplicado em `public.speedrun_ranks` separa exatamente as duas categorias competitivas (**`manual`** e **`auto_hunt`**), garante unicidade por corrida (`run_uid`) para evitar submissões duplicadas e impede `UPDATE` ou `DELETE` por clientes:

```sql
create table if not exists public.speedrun_ranks (
  id uuid primary key default gen_random_uuid(),
  run_uid uuid not null unique default gen_random_uuid(),
  player_name text not null,
  category text not null,
  time_seconds numeric(10, 2) not null,
  level integer not null,
  total_kills integer not null default 0,
  bosses_defeated smallint not null default 6,
  game_version text not null,
  created_at timestamptz not null default now(),
  constraint speedrun_ranks_player_name_chk check (
    player_name = btrim(player_name)
    and char_length(player_name) between 2 and 20
    and player_name !~ '[[:cntrl:]<>]'
  ),
  constraint speedrun_ranks_category_chk check (
    category in ('manual', 'auto_hunt')
  ),
  constraint speedrun_ranks_time_seconds_chk check (
    time_seconds >= 10 and time_seconds <= 864000
  ),
  constraint speedrun_ranks_level_chk check (
    level >= 1 and level <= 999
  ),
  constraint speedrun_ranks_total_kills_chk check (
    total_kills >= 0 and total_kills <= 10000000
  ),
  constraint speedrun_ranks_bosses_chk check (
    bosses_defeated >= 1 and bosses_defeated <= 6
  ),
  constraint speedrun_ranks_version_chk check (
    char_length(game_version) between 3 and 16
    and game_version ~ '^[0-9]+\.[0-9]+\.[0-9]+([\-+][A-Za-z0-9\.-]+)?$'
  )
);

create index if not exists speedrun_ranks_category_time_idx
  on public.speedrun_ranks (category, time_seconds asc, created_at asc);

alter table public.speedrun_ranks enable row level security;

revoke all on table public.speedrun_ranks from public, anon, authenticated;
grant select, insert on table public.speedrun_ranks to anon, authenticated;
grant all on table public.speedrun_ranks to service_role;

create policy "Public leaderboard is readable by everyone"
  on public.speedrun_ranks
  for select
  to anon, authenticated
  using (true);

create policy "Anyone can submit a validated speedrun"
  on public.speedrun_ranks
  for insert
  to anon, authenticated
  with check (
    category in ('manual', 'auto_hunt')
    and time_seconds >= 10
    and time_seconds <= 864000
    and player_name = btrim(player_name)
    and char_length(player_name) between 2 and 20
    and level between 1 and 999
    and bosses_defeated between 1 and 6
  );
```

> Também foi revogado `EXECUTE` de `public.rls_auto_enable()` para `public`, `anon` e `authenticated`, zerando todos os alertas dos Security Advisors do Supabase.

---

## 3. Fluxo no Cliente Godot (`GameState.gd` + `LeaderboardService.gd`)

1. **Rastreamento Fiel da Categoria:**
   * `GameState.used_auto_hunt_in_run` nasce `false` em toda nova aventura e só é resetado em `GameState.reset_save()`.
   * Ativar `Auto: ON` mesmo que por um instante define definitivamente `used_auto_hunt_in_run = true` (persistido em `user://savegame.json`), classificando a run como **`Com Auto-Hunt`**.
   * Ao iniciar o resgate do Barão Ragnar (`Main.gd:play_ending_cutscene()`), `GameState.freeze_victory_run()` marca `victory_achieved = true` e congela `play_time_seconds`.
2. **Persistência Local Independente (`user://speedrun_ranks.json`):**
   * Fica separada de `user://savegame.json`, permitindo iniciar **Novo Jogo** sem apagar os recordes pessoais locais nem o apelido salvo.
   * Funciona como *fallback* automático quando o navegador estiver offline ou a API temporariamente inacessível.
