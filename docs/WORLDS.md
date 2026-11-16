# 🌍 Mundos e Mapas — Dragon Adventure: O Último Herói

*(Sincronizado com [`scripts/TibiaTileEngine.gd`](../scripts/TibiaTileEngine.gd) e [`autoload/GameData.gd`](../autoload/GameData.gd).)*

## 1. Arquitetura dos Cenários (`TibiaTileEngine.gd`)
Todos os 5 mapas utilizam imagens panorâmicas `fenaky_<id>.png` (`res://assets/tiles/fenaky_<id>.png`) em escala **64 × 36 tiles** de `32 px` (`2048 × 1152 px`), combinadas com:
* Grid de caminhabilidade `AStarGrid2D` para navegação de **Auto-Hunt**, *Click-to-Walk* e inimigos;
* Pontes liberadas sobre rios/abismos (`_mark_bridge_rect`), bordas sólidas e obstáculos circulares de casas, torres, estátuas e fogueiras;
* **Portais Interativos (`ZonePortal.gd`):** Permitem viagem caminhando ou por clique, exibindo trava `[SELADO]` caso o chefe necessário ainda não tenha sido derrotado;
* **Margens de Câmera (`Main.gd`):** Limites `limit_top = -56`, `limit_right = int(map_width) + 256`, `limit_bottom = int(map_height) + 64`, mantendo portais e jogador sempre visíveis fora da HUD direita (`Hunt Analyzer` + `MinimapWidget`);
* **Viagem Híbrida (`HuntsMapModal.gd`):** Além de caminhar pelos portais, o botão `Mapa` permite teletransporte direto entre qualquer mapa desbloqueado.

---

## 2. Mapa Central (Hub Pacífico)

### Vila Barão Ragnar (`vila`)
* **Tipo:** Zona Segura (`safe_hub` — sem spawn de monstros).
* **BGM:** Tema medieval de suspense (`bgm_vila.mp3`), transmitindo a tensão iminente de invasão.
* **Habitantes & Serviços:**
  * **Aldeão (`aldeao`):** Conta a queda das outras vilas e o sumiço do Barão Ragnar.
  * **Vendedor (`vendedor`):** Ao sul da praça, junto à tenda de comércio (`vila_stall`), abre a **Loja (`ShopModal`)**.
* **Portal:** **Floresta dos Ecos** posicionado na clareira logo após a saída leste da ponte (`Vector2(55.0 * 32, 18.0 * 32)`).

---

## 3. Progressão das Zonas de Caçada (`hunt_zone`)

### 🌲 Mapa 1: Floresta dos Ecos (`floresta`)
* **Tipo:** Zona de Caçada Inicial (ponto de partida da campanha após o prólogo).
* **Requisitos de Chefe:** **8 abates** na sessão para habilitar `Desafiar Chefe`.
* **Hunt Spots (4 setores em rodízio):** North-West Spot (Toupeiras), South-West Spot (Zumbis/Esqueletos), North-East Spot e South-East Spot.
* **NPC:** **Explorador** no acampamento central da fogueira.
* **Chefes:** 1º **Lobisomem** (desbloqueia Tornado `[2]`) ➔ 2º **Toupeira Serra** (desbloqueia Bomba de Água `[3]` e as **Cavernas e Minas**).
* **Portais:** Oeste ➔ `Vila Barão Ragnar`; Leste ➔ `Cavernas e Minas` (requer `toupeira_serra`).

### ⛏️ Mapa 2: Cavernas e Minas (`caverna`)
* **Tipo:** Zona de Caçada Intermediária.
* **Requisitos de Chefe:** **12 abates** na sessão para habilitar `Desafiar Chefe`.
* **Hunt Spots (4 setores):** Galeria Oeste, Trilho Sul, Gruta dos Cristais (NE) e Covil da Aranha (SE) com **Humanos Mineradores**, **Robôs** e **Toupeiras**.
* **NPC:** **Explorador** no acampamento subterrâneo.
* **Chefes:** 1º **Robô Toupeira Serra** ➔ 2º **Robô Aranha** (libera o **Castelo de Lunário**).
* **Portais:** Oeste ➔ `Floresta dos Ecos`; Leste ➔ `Castelo de Lunário` (requer `robo_aranha`).

### 🏰 Mapa 3: Castelo de Lunário (`castelo`)
* **Tipo:** Zona de Caçada Final.
* **Requisitos de Chefe:** **15 abates** na sessão para habilitar `Desafiar Chefe`.
* **Hunt Spots (4 alas conectadas por 4 pontes douradas):** Cripta Esqueleto, Salão dos Ossos, Salão dos Guardiões e Salão Lunar com **Fantasmas**, **Robôs**, **Esqueletos** e **Espectros de Slime**.
* **NPC:** **Explorador** próximo às escadarias sul.
* **Chefes:** 1º **O Dragão** ➔ 2º **Lunário, o Deus Dragão** (libera a **Cabana Inimiga Distante**).
* **Portais:** Oeste ➔ `Cavernas e Minas`; Leste ➔ `Cabana Inimiga Distante` (requer `lunario`).

---

## 4. Cenário Especial do Epílogo (`epilogue`)

### 🏚️ Cabana Inimiga Distante (`cabana`)
* **Tipo:** Área isolada do desfecho (sem spawn de monstros comuns).
* **Objetivo:** Atravessar a ponte oeste e interagir (`[E]`) com **Barão Ragnar (Pai)** diante da cabana fortificada para assistir à cutscene final de reencontro e concluir a campanha (`VictoryModal`).
