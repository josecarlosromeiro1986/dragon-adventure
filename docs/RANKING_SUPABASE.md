# Ranking Global Online (Supabase + Fallback Local)

Documentação da arquitetura de backend e banco de dados do **Sistema de Rank Global / Speedrun** introduzido na **Issue #9 (`v1.3.0`)**.

---

## 1. Projeto Supabase e Modelo de Segurança

* **Project Ref:** `tgwoptupssqptvpmuija`
* **Endpoint REST de Leitura:** `https://tgwoptupssqptvpmuija.supabase.co/rest/v1/speedrun_ranks` (`SELECT` público via RLS)
* **Endpoint RPC de Submissão:** `https://tgwoptupssqptvpmuija.supabase.co/rest/v1/rpc/submit_speedrun_score`
* **Autenticação no Cliente WebGL (`autoload/LeaderboardService.gd`):**
  * Utiliza **apenas** a `SUPABASE_URL` pública e a `Publishable Key` pública (`sb_publishable_...`) enviada no cabeçalho HTTP `apikey`.
  * **Nenhuma** `service_role`, `secret` key ou senha do PostgreSQL existe no código-fonte ou no pacote `.pck` exportado para WebGL.
  * Escritas diretas (`INSERT`, `UPDATE`, `DELETE`) em `public.speedrun_ranks` ficam **revogadas** para `anon`/`authenticated`; toda publicação passa pela RPC `public.submit_speedrun_score(...)` com validação rigorosa de entrada e controle de propriedade em `private.speedrun_owners` (`sha256` do token local).

---

## 2. Schema SQL, Unicidade de Apelido e Políticas RLS

O schema garante:
1. Separação competitiva nas categorias **`manual`** e **`auto_hunt`**.
2. **Apelido único global (*case-insensitive*) por jogador:** o primeiro envio de um apelido vincula `lower(btrim(player_name))` ao hash SHA-256 do `player_token` gerado localmente no navegador (`private.speedrun_owners`, inacessível via Data API).
3. **Atualização segura de recorde próprio:** apenas o dono do token pode enviar novamente com aquele apelido; se bater seu tempo naquela categoria, seu registro é atualizado mantendo **1 melhor tempo por jogador/categoria**.

```sql
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.speedrun_owners (
  name_key text primary key,
  owner_token_hash text not null,
  created_at timestamptz not null default now()
);

alter table private.speedrun_owners enable row level security;
revoke all on table private.speedrun_owners from public, anon, authenticated;
grant all on table private.speedrun_owners to service_role;

create policy "No direct access to speedrun owners"
  on private.speedrun_owners
  for all
  to anon, authenticated
  using (false)
  with check (false);

create unique index if not exists speedrun_ranks_unique_name_cat_idx
  on public.speedrun_ranks (lower(btrim(player_name)), category);

revoke insert, update, delete on table public.speedrun_ranks from public, anon, authenticated;
grant select on table public.speedrun_ranks to anon, authenticated;
```

> A definição completa da função RPC `public.submit_speedrun_score(uuid, text, text, numeric, integer, integer, integer, text, text)` (`SECURITY DEFINER SET search_path = ''`) está aplicada diretamente no projeto Supabase e bloqueia `invalid_name`, `name_taken` e tempos `< 10s`.

---

## 3. Fluxo no Cliente Godot (`GameState.gd` + `LeaderboardService.gd`)

1. **Rastreamento Fiel da Categoria:**
   * `GameState.used_auto_hunt_in_run` nasce `false` em toda nova aventura e só é resetado em `GameState.reset_save()`.
   * Ativar `Auto: ON` mesmo que por um instante define definitivamente `used_auto_hunt_in_run = true` (persistido em `user://savegame.json`), classificando a run como **`Com Auto-Hunt`**.
   * Ao iniciar o resgate do Barão Ragnar (`Main.gd:play_ending_cutscene()`), `GameState.freeze_victory_run()` marca `victory_achieved = true` e congela `play_time_seconds`.
2. **Apelido Próprio + Persistência Local Independente (`user://speedrun_ranks.json`):**
   * O campo de apelido inicia **vazio** na primeira vitória (sem pré-preencher `"Daniel Ragnar"`), exigindo que cada jogador escolha seu apelido único.
   * Armazena `player_token` e o histórico local de corridas separado de `user://savegame.json`, permitindo iniciar **Novo Jogo** sem apagar recordes nem perder a titularidade do apelido no navegador.
   * Funciona como *fallback* automático quando o navegador estiver offline ou a API temporariamente inacessível.
