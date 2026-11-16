# ⚔️ Itens, Combate e Economia — Dragon Adventure: O Último Herói

*(Valores sincronizados exatamente com [`autoload/GameData.gd`](../autoload/GameData.gd) e [`scripts/ShopModal.gd`](../scripts/ShopModal.gd).)*

## 1. Sistema de Armas (`GameData.WEAPONS`)
O jogo conta com **2 categorias** (**Espadas** e **Martelos**) distribuídas em **4 tiers** (**Madeira, Pedra, Ouro, Diamante**):

### Espadas (Ataque Ágil + Acerto Crítico)
| ID | Nome | Tier / Raridade | Dano | Cooldown | Crit | Preço (Notas) |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| `sword_wood` | Espada de Madeira | 1 (Comum) | 12 | 0.35s | 5% | Inicial (`$ 0`) |
| `sword_stone` | Espada de Pedra | 2 (Incomum) | 25 | 0.35s | 10% | `$ 150` |
| `sword_gold` | Espada de Ouro | 3 (Raro) | 55 | 0.30s | 25% | `$ 600` |
| `sword_diamond` | Espada de Diamante | 4 (Lendário) | 120 | 0.28s | 35% | `$ 1.800` |

### Martelos (Ataque Pesado + Chance de Atordoar)
| ID | Nome | Tier / Raridade | Dano | Cooldown | Crit | Atordoar | Preço (Notas) |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `hammer_wood` | Martelo de Madeira | 1 (Comum) | 20 | 0.65s | 5% | 20% | `$ 50` |
| `hammer_stone` | Martelo de Pedra | 2 (Incomum) | 45 | 0.60s | 10% | 25% | `$ 200` |
| `hammer_gold` | Martelo de Ouro | 3 (Raro) | 95 | 0.55s | 20% | 35% | `$ 750` |
| `hammer_diamond` | Martelo de Diamante | 4 (Lendário) | 210 | 0.50s | 30% | 50% | `$ 2.200` |

* **Efeitos Visuais por Raridade (`GameData.RARITIES`):** Os tiers 2, 3 e 4 adicionam brilho/aura na arma, rastro de golpe mais espesso e partículas proporcionais ao nível do equipamento.

---

## 2. Sistema de Armaduras (`GameData.ARMORS`)
As armaduras reduzem todo dano recebido em percentual e trocam o sprite completo de Daniel para a versão blindada correspondente mantendo sua faixa vermelha:

| ID | Nome | Tier / Raridade | Redução de Dano | Preço (Notas) |
| :--- | :--- | :--- | :---: | :---: |
| `none` | Roupas Simples | 0 (Básico) | 0% | Inicial (`$ 0`) |
| `armor_wood` | Armadura de Madeira | 1 (Comum) | 10% | `$ 80` |
| `armor_stone` | Armadura de Pedra | 2 (Incomum) | 25% | `$ 250` |
| `armor_gold` | Armadura de Ouro | 3 (Raro) | 45% | `$ 900` |
| `armor_diamond` | Armadura de Diamante | 4 (Lendário) | 70% | `$ 2.400` |

---

## 3. Poderes Mágicos Elementais (`GameData.SPELLS`)

| Tecla | Magia | Elemento | Dano Base | Mana | Cooldown | Como Desbloquear |
| :---: | :--- | :---: | :---: | :---: | :---: | :--- |
| `1` / `J` | **Bola de Fogo** (`fireball`) | Fogo | 45 | 15 | 3.0s | Liberada desde o início |
| `2` / `K` | **Tornado** (`tornado`) | Vento | 60 | 20 | 5.0s | Derrotar **Lobisomem** (ou chefes posteriores / falar com Explorador nas Cavernas) |
| `3` / `L` | **Bomba de Água** (`water_bomb`) | Água | 90 | 25 | 6.0s | Derrotar **Toupeira Serra** (ou chefes posteriores / falar com Explorador nas Cavernas) |

* **Tooltip de Desbloqueio (`HUD.gd`):** Enquanto uma magia estiver bloqueada, passar o mouse sobre seu slot rúnico na barra inferior exibe um popup explicando como liberá-la; após desbloqueada, o popup de bloqueio deixa de aparecer.
* **Voz nas Invocações:** Daniel pronuncia a fala da magia (`daniel_fireball`, `daniel_tornado`, `daniel_water_bomb`) com controle de cooldown de áudio.

### Multiplicadores Elementais (`GameData.get_elemental_multiplier`)
* **🔥 Fogo (`x2 SUPER EFETIVO!`):** `zumbi`, `lobisomem`, `toupeira`, `toupeira_serra`, `espectro_slime`.
* **🌪️ Vento (`x2 SUPER EFETIVO!`):** `esqueleto`, `fantasma`, `espectro_slime`.
* **💧 Água (`x2 SUPER EFETIVO!`):** `robo`, `robo_toupeira_serra`, `robo_aranha`, `dragao`.

---

## 4. Economia, Loja e Comidas Inteligentes

### 💵 Dinheiro em Notas (`CashNote.gd`)
* Todo monstro derrotado solta cédulas de papel (`cash_min` a `cash_max`), coletadas por proximidade magnética.
* A exibição de notas na **HUD** (`$ X Notas`), na **Loja** (`Suas Notas: $ X`) e na **Mochila** (`Notas: $ X`) usa o mesmo componente visual padronizado (`MedievalUI.notes_pill_box`).
* Na **Loja (`ShopModal.gd`)**, itens cujo preço excede `GameState.cash_notes` ficam com o botão `Comprar` **desabilitado** (estilo pedra acinzentado + tooltip `"Saldo insuficiente"`). Itens já comprados exibem `Equipar` / `Equipada`.

### 🍎 Comidas de Cura (`GameData.FOODS`)
| ID | Nome | Cura | Preço (Notas) | Estoque Inicial |
| :--- | :--- | :---: | :---: | :---: |
| `apple` | Maçã Silvestre | `+30 HP` | `$ 15` | 5 |
| `bread` | Pão da Vila | `+75 HP` | `$ 35` | 2 |
| `meat` | Carne Assada | `+180 HP` | `$ 80` | 0 |

* **Consumo Inteligente (`GameState.eat_food`):** Ao pressionar `Q`/`C` ou ativar o Auto-Comer (`HP < 50%`), o jogo escolhe a comida ideal pela quantidade de vida perdida (`missing >= 130` prioriza Carne; `missing >= 55` prioriza Pão; abaixo disso prioriza Maçã, com fallback para as disponíveis) e registra o gasto equivalente no **Hunt Analyzer**.
