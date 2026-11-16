# 🕰️ Histórico de Desenvolvimento — Dragon Adventure: O Último Herói

Este documento registra a linha do tempo real de construção do **Dragon Adventure: O Último Herói** — desde a ideia original criada por **Daniel** e seu pai (**José Carlos Romeiro**) em **11 de novembro de 2026** até a publicação pública no GitHub em **16 de novembro de 2026** (ao longo de **108 interações** de concepção, direção de arte, áudio, programação, QA e revisão).

---

## 📜 1. O Prompt Inicial (Fiel ao Original)

Abaixo está o texto exato enviado na abertura do projeto em **11/11/2026 às 20:41 (BRT)**, preservando integralmente a ideia concebida em família:

```text
Meu filho montou essa hoistoria, quero a tranformar em um jogo de navegador pixel art.
Ajuste a narrativa e seus itens, não altere muita coisa, somente o necessário, vamos apenas montar a narrativa e os elementos.

O player vai ser um cara com um laço vermelho na cabeça e uma camisa simples e calça tamem.
Armas espada e martelo ambos de madeira, pedra, ouro, diamante.
Amaduras madeira, pedra, ouro, diamante.
Montros topera,esqueleto, zumbi, robo, humano minerador, fantasma.
Boss lobsomem, topera serra, robo topeira serra, robo aranha, dragão, deus dragão (nome Lunário).
NPC humano normal -> conversar contar a narrativa do jogo, esplorador -> ele fica andando no mapar fazendo exploração, vendedor -> armas, comida e armaduras.
Poderes bola de fogo, tornado, bomba de agua.
Mapas floresta, caverna e castelo.
Tipo do jogo exploração e matar monstro dropa os dinhiros em nota.
História, o deus dragão fez os monstros, que distruiram as vilas, o heroi é o personagem principal (player nome Daniel Ragnar) que vive na ultima vila (Vila Barão Ragnar em homenagem ao sei pai o chefe da vila) que não foi destruida. O pai do heroi (nome Barão Ragnar) lutou com o dragão mas não conseguiu derrotar, depois da batalha ele sumiu, ao final o heroi  vai reencontrar seu pai que estava preso em uma cabalna inimiga bem longe da sua vila.
Nome do jogo Dragon Adventure subnome o ultimo heroi
```

Logo na sequência (`11/11/2026 às 21:19`), veio o primeiro ajuste essencial de identidade do protagonista:

> *"o Daniel Ragnar é menino e não é uma laço e sim uma faixa."*

---

## 🗓️ 2. Cronologia Completa da Construção (11/11/2026 → 16/11/2026)

### Marco 1 — Narrativa, Documentação Base e Referência de Gameplay (`11/11/2026`)
- **Estruturação da Bíblia do Jogo:** Organização modular da documentação em Markdown (`docs/`) para servir de fonte de verdade tanto para humanos quanto para agentes de IA.
- **Referência de Estilo e Interface:** Análise de referência inspirada em *Poke Idle League* (`#hunts`), definindo o formato de **caçadas contínuas (Hunts)**, combate híbrido manual/automático e o painel de telemetria **Hunt Analyzer** em tempo real.

---

### Marco 2 — Pipeline de Arte & Áudio e Escolha da Engine (`12/11/2026 — manhã`)
- **PixelLab.ai:** Integração inicial para geração de sprites pixel art (começando na cota gratuita de 40 gerações e, mais tarde no mesmo dia, evoluindo para o plano *Tier 1: Pixel Apprentice* com 2.000 gerações).
- **ElevenLabs:** Integração com cota de 30.000 créditos para efeitos sonoros (SFX), músicas e dublagens dos personagens.
- **Stack Oficial Definida:** Escolha pela **Godot Engine 4 (GDScript)** com exportação Web (`gl_compatibility` / WebGL 2.0) homologada para o navegador **Google Chrome**, substituindo o protótipo inicial em HTML5 puro (posteriormente isolado em `_archive/`).

---

### Marco 3 — Protótipo Jogável e Refino das Animações de Daniel (`12/11/2026 — manhã/tarde`)
- **Execução do Plano Base:** Criação da arquitetura de autoloads (`GameData`, `GameState`, `HuntAnalyzerData`, `SpriteFactory`, `AudioManager`), cena principal, movimento, combate, drops de cédulas e loja inicial.
- **Controle de Qualidade Visual:** Ao notar personagens estáticos e animações iniciais abaixo do padrão desejado, houve revisão dedicada no PixelLab — removendo animações manuais/ruins de Daniel e recriando os 4 primeiros personagens com fidelidade à **faixa vermelha na testa** com pontas esvoaçantes.

---

### Marco 4 — Auditoria de *Game Feel* ("Juice") e Interação com NPCs (`12/11/2026 — tarde`)
- **Auditoria Sênior Antes de Alterar Código:** Mapeamento do game loop, inputs, física e limites de tela para elevar a responsividade do jogo:
  - *Screen shake* proporcional e *hitstop* nos golpes e críticos;
  - Partículas e feedbacks visuais (`FloatingText`);
  - Ajuste nas janelas de diálogo do Explorador para abrir e fechar apenas com a tecla **`[E]`**, sem disparo automático indesejado ao encostar.

---

### Marco 5 — Interface Medieval via Conceito + PixelLab UI (`12/11/2026 — noite`)
- **Artes Conceituais de Menus:** Geração de imagens conceituais estilo RPG medieval antes da implementação dos painéis.
- **Fidelidade com `create-ui` / 9-Slice:** Adoção direta do MCP do PixelLab para construir componentes 9-slice em pixel art (`MedievalUI.gd`) fiéis aos conceitos aprovados (pergaminho, molduras douradas, barras e botões).

---

### Marco 6 — Criação dos 5 Mundos em Pixel Art via Fenaky + Godot (`13/11/2026`)
- **Busca pelo Estilo Clássico (*Tibia / Poke Idle*):** Após tentativas iniciais com tiles gerados proceduralmente/JSON que não ficaram fiéis ao desejado, foi definido um fluxo em duas etapas:
  1. Geração e validação prévia de **imagens conceituais** para cada bioma;
  2. Geração dos mapas finais `64×36` (`2048×1152 px`) via **MCP da Fenaky** acompanhados de matriz de colisão, pontes caminháveis e navegação **`AStarGrid2D`** no [`TibiaTileEngine.gd`](../scripts/TibiaTileEngine.gd).
- **Os 5 Mundos:** Vila Barão Ragnar (Hub), Floresta dos Ecos, Cavernas e Minas, Castelo de Lunário e Cabana Inimiga Distante.

---

### Marco 7 — Equipamentos, Inventário `[I]` e Auto-Hunt Inteligente (`14/11/2026 — manhã/tarde`)
- **Validação de Arsenal:** Criação prévia de imagens conceituais das **Espadas**, **Martelos** e **Armaduras** nos 4 tiers (**Madeira → Pedra → Ouro → Diamante**) antes da geração final dos sprites.
- **Mochila e Visual Equipado:** Implementação do modal de Inventário (`[I]`), exibição dinâmica da arma na mão de Daniel e efeitos visuais de ataque graduados pela raridade da arma.
- **Auto-Hunt com Desvio A*:** Correção de travamentos no modo automático (`[R]`) para contornar obstáculos e buscar monstros caminháveis via `AStarGrid2D`.
- **Bloqueio de Modais:** Pausa automática do jogo ao abrir janelas/diálogos e bloqueio de cliques de ataque através da interface.

---

### Marco 8 — Trilha Épica, Magias, Cutscenes e Dublagem `pt-BR` (`14/11/2026 — noite`)
- **Trilha Sonora Progressiva:** Composição das músicas medievais por bioma — tema de **suspense** na Vila (sob ameaça iminente) e trilhas **épicas com intensidade crescente** nas zonas de caça.
- **Sistema de Magias Corrigido:** Garantia do desbloqueio correto de `Tornado [2]` e `Bomba de Água [3]` ao derrotar chefes, mais **tooltip dinâmico** ao passar o mouse explicando como liberar magias bloqueadas (ocultado após desbloqueio).
- **Cutscenes e Vozes Naturais em `pt-BR`:**
  - Cutscene do Prólogo na abertura, cutscenes exclusivas ao invocar cada um dos **6 chefes** e cutscene final do resgate do **Barão Ragnar**;
  - Regeneração das vozes em **português brasileiro (`pt-BR`)** natural (adequando o timbre à idade de Daniel, voz dedicada ao Barão Ragnar e vozes malignas distintas para cada chefe, sincronizadas com o texto exibido);
  - Voz padrão nas invocações de magia e desativação automática do botão **Desafiar Chefe** quando todos os chefes da zona já foram vencidos.

---

### Marco 9 — Polimento de QA, Blueprint para IAs e Novo Monstro (`15/11/2026`)
- **Correções Visuais e de Combate reportadas em Teste Real:**
  - Correção de ícones faltantes e restauração do ataque com **clique esquerdo** na direção do cursor;
  - Padronização visual das pílulas de **Notas (`notes_pill_box`)** e desativação visual do botão **Comprar** quando o jogador não possui saldo;
  - Expansão das margens da `Camera2D` e reposicionamento estratégico para evitar que o portal da Vila ficasse escondido atrás do Minimapa e do Hunt Analyzer.
- **Guia Replicável para IAs ([`AI_GAME_BLUEPRINT.md`](./AI_GAME_BLUEPRINT.md)):** Criação de documentação arquitetural completa ensinando outras IAs a construir um jogo nesse padrão do zero.
- **Novo Monstro — Espectro de Slime (`espectro_slime`):** Adição do 7º monstro comum no **Castelo de Lunário** — criatura humanoide dividida entre metade slime roxo (esquerda) e metade fantasma espectral de plasma (direita), alternando projéteis distintos lançados diretamente de cada mão (`slime_orb` e `plasma_bolt`).

---

### Marco 10 — Auditoria Geral, Hardening de Segurança e Publicação no GitHub (`15/11/2026 — noite` → `16/11/2026`)
- **Revisão Completa de Segurança e Clean Code:**
  - Migração de chaves de API dos scripts PowerShell para variáveis de ambiente (`PIXELLAB_API_KEY` e `ELEVENLABS_API_KEY`) com [`.env.example`](../.env.example);
  - Correção de *path traversal* (`403`) e CORS restrito a `localhost` no servidor HTTP local ([`run_web_chrome.ps1`](../scripts/run_web_chrome.ps1));
  - Proteções de runtime e carregamento de save em [`GameState.gd`](../autoload/GameState.gd), throttling em [`HuntAnalyzerData.gd`](../autoload/HuntAnalyzerData.gd), checagens de pausa/instância em [`ZonePortal.gd`](../scripts/ZonePortal.gd) e [`CashNote.gd`](../scripts/CashNote.gd);
  - Remoção de ~637 linhas de código morto em [`TibiaTileEngine.gd`](../scripts/TibiaTileEngine.gd), centralização de helpers (`FloatingText.spawn`, `GameData.get_map_bounds`, `MedievalUI.create_notes_badge`), isolamento do protótipo antigo em `_archive/` e adição de docstrings `##`;
  - Exportação limpa do preset Web em `Godot 4.7.2` e verificação end-to-end no Chrome WebGL com `0` erros no console.
- **Publicação Pública:** Configuração do **MCP do GitHub** (token sem permissão `delete_repo`), criação da documentação completa de repositório ([`README.md`](../README.md), [`CONTRIBUTING.md`](../CONTRIBUTING.md), [`.gitattributes`](../.gitattributes) e templates em `.github/`), conversão de todos os links locais em `docs/` para links relativos e publicação pública em [`josecarlosromeiro1986/dragon-adventure`](https://github.com/josecarlosromeiro1986/dragon-adventure).

---

## 📊 Resumo Quantitativo da Jornada

| Métrica | Valor Alcançado |
| :--- | :--- |
| **Período de Criação** | `11/11/2026` a `16/11/2026` (`108` interações do criador) |
| **Mundos Jogáveis** | `5` mapas (`64×36` tiles / `2048×1152 px`) |
| **Bestiário** | `7` monstros comuns + `6` chefes com cutscene e voz própria |
| **Equipamentos & Magias** | `4` tiers (Madeira, Pedra, Ouro, Diamante) em Espadas, Martelos e Armaduras + `3` magias |
| **Documentação Modular** | `12` documentos em `docs/` + guias raiz (`README.md`, `CONTRIBUTING.md`) |
| **Base Versionada** | `1.820+` arquivos organizados no repositório público `main` |
