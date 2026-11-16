# 📜 Narrativa e Enredo — Dragon Adventure: O Último Herói

## 1. Sinopse Geral
Em um mundo outrora próspero, o colossal **Deus Dragão Lunário** criou hordas de monstros destruidores que varreram quase todas as civilizações. Das dezenas de vilarejos existentes, restou apenas um: a **Vila Barão Ragnar**, batizada em honra ao seu respeitado líder e guerreiro, o **Barão Ragnar**.

O Barão marchou com bravura para enfrentar o dragão antes que a última vila sucumbisse, mas desapareceu misteriosamente após a batalha. Sem seu protetor e com as forças inimigas se aproximando, **Daniel Ragnar**, o jovem filho do Barão, amarra sua **faixa vermelha na testa**, empunha sua espada e parte como o **Último Herói** para derrotar os chefes de cada região, deter Lunário e resgatar o próprio pai.

---

## 2. Estrutura Narrativa & Cutscenes Implementadas (`CutsceneModal.gd` / `Main.gd`)

### Prólogo Cinematográfico (3 Capítulos Dublados)
Exibido automaticamente ao iniciar uma nova aventura (e re-assistível a qualquer momento em `Config / Som` ➔ `"Rever Prólogo da História"`):
1. **Capítulo I — O Ataque dos Dragões:** O **Ancião da Vila** (`intro_1_ataque`) relata como Lunário despertou com seu exército e destruiu quase todo o reino.
2. **Capítulo II — O Desaparecimento do Barão Ragnar:** O Ancião (`intro_2_barao`) conta que apenas a Vila Barão Ragnar resistiu graças à bravura do Barão antes de desaparecer enfrentando o dragão.
3. **Capítulo III — A Promessa do Último Herói:** **Daniel Ragnar** (`daniel_intro`, voz infantil/jovem pt-BR natural) jura vencer cada chefe, derrotar Lunário e trazer seu pai de volta.

### Ato I: Floresta dos Ecos
* Daniel conversa com o **Aldeão** (`aldeao_intro`) e com o **Vendedor** (`vendedor_ola`) na Vila Barão Ragnar, e atravessa a ponte leste rumo à **Floresta dos Ecos**.
* O **Explorador** (`explorador_floresta_1` / `explorador_floresta_2`) orienta sobre a magia **Bola de Fogo** (`[1]`) contra Toupeiras e Zumbis.
* **Confrontos com Cutscene Dublada:**
  * Sub-Chefe **Lobisomem** (`boss_lobisomem`) ➔ desbloqueia a magia **Tornado** (`[2]`).
  * Chefe **Toupeira Serra** (`boss_toupeira_serra`) ➔ desbloqueia a magia **Bomba de Água** (`[3]`) e abre o portal das **Cavernas e Minas**.

### Ato II: Cavernas e Minas
* Daniel encontra humanos mineradores corrompidos e robôs escavadores a vapor.
* O **Explorador** (`explorador_caverna_1` / `explorador_caverna_2`) reforça o uso do **Tornado** (`[2]`) e da **Bomba de Água** (`[3]`) para causar curto-circuito (`x2`) nos robôs.
* **Confrontos com Cutscene Dublada:**
  * Sub-Chefe **Robô Toupeira Serra** (`boss_robo_toupeira_serra`).
  * Chefe **Robô Aranha** (`boss_robo_aranha`) ➔ abre o acesso ao **Castelo de Lunário**.

### Ato III: Castelo de Lunário
* Na fortaleza flutuante tomada por fantasmas, robôs de elite, esqueletos e espectros de slime, o **Explorador** (`explorador_castelo`) dá as instruções finais antes do duelo contra os dragões.
* **Confrontos com Cutscene Dublada:**
  * Sub-Chefe **O Dragão** (`boss_dragao`), o executor que combateu o Barão Ragnar.
  * Chefe Final **Lunário, o Deus Dragão** (`boss_lunario`) com ataque de duas fases; ao ser derrotado, revela o caminho até a **Cabana Inimiga Distante**.

### Epílogo: O Reencontro na Cabana (`play_ending_cutscene`)
* Daniel chega à **Cabana Inimiga Distante** e conversa com **Barão Ragnar (Pai)**.
* **Cutscene Final (2 Cenas Dubladas):**
  1. **Daniel Ragnar** (`daniel_victory`): *"Pai! Eu consegui! O Deus Dragão Lunário foi derrotado e eu vim buscar o senhor!"*
  2. **Barão Ragnar (Pai)** (`barao_resgate`): *"Daniel... meu filho! Você cruzou todo o reino, derrotou o Deus Dragão Lunário e veio me salvar com sua faixa vermelha! Você é o verdadeiro Último Herói! A Vila Barão Ragnar está a salvo para sempre!"*
* Ao concluir, o jogo abre a `VictoryModal` com estatísticas da campanha (nível, notas, monstros derrotados e equipamento final).

---

## 3. Regra de Coerência Texto × Dublagem
Todo texto exibido no `CutsceneModal` e no `DialogueBox` corresponde exatamente ao roteiro gravado nos arquivos MP3 de `assets/audio/voices/`, com vozes diferenciadas por faixa etária e personalidade em português brasileiro (`pt-BR`).
