# 👥 Personagens e NPCs — Dragon Adventure: O Último Herói

## 1. Protagonista

### Daniel Ragnar (O Menino Herói)
* **Papel:** Personagem Jogável (`scripts/Player.gd`).
* **Identidade:** Menino corajoso e destemido, filho do Barão Ragnar, com voz jovem em `pt-BR` (`daniel_intro`, `daniel_boss_challenge`, `daniel_fireball`, `daniel_tornado`, `daniel_water_bomb`, `daniel_levelup`, `daniel_victory`).
* **Aparência e Visual Pixel Art:**
  * **Faixa Vermelha:** Bandana/faixa vermelha marcante amarrada na testa, com as pontas do nó esvoaçando para trás (não é laço e não é adulto).
  * **Vestimenta Base:** Camisa rústica simples, calça marrom de viagem e botas de aventureiro.
* **Evolução Visual de Armaduras (PixelLab 4D + Animações):**
  * Conforme equipa as armaduras de **Madeira** (`daniel_armor_wood`), **Pedra** (`daniel_armor_stone`), **Ouro** (`daniel_armor_gold`) e **Diamante** (`daniel_armor_diamond`), todo o sprite do personagem reflete a armadura mantendo a faixa vermelha sempre em evidência, além de renderizar a arma equipada e sua aura elemental/raridade.
* **Estilo de Combate:** Alterna livremente entre Espadas (rápidas) e Martelos (pesados com atordoamento), além das 3 magias elementais e ataque direcionado ao cursor.

---

## 2. Personagem Chave da Trama

### Barão Ragnar (O Pai Desaparecido)
* **Papel:** Líder da Vila Barão Ragnar, guerreiro lendário em armadura prateada com ombreiras douradas e capa vermelha (`assets/barao/`).
* **Localização:** Encontrado prisioneiro na **Cabana Inimiga Distante** (`cabana`, área leste).
* **Interação Final (`[E]`):** Dispara a cutscene final de reencontro com fala dublada (`barao_resgate`) e libera a tela de vitória (`VictoryModal`).

---

## 3. NPCs (`scripts/NPC.gd` + Indicadores Flutuantes)
Todos os NPCs exibem um indicador visual animado acima da cabeça (`NPCIndicator`: balão `[E]` ou ícone `$` para o Vendedor) e pausam o jogo enquanto a janela de diálogo/loja está aberta:

1. **Aldeão / Ancião da Vila (`aldeao`):**
   * **Local:** Praça da Vila Barão Ragnar (`Vector2(768, 576)`).
   * **Função:** Contextualiza o ataque de Lunário e o sumiço do Barão Ragnar com dublagem (`aldeao_intro`), além de narrar os capítulos I e II do Prólogo.
2. **Vendedor (`vendedor`):**
   * **Local:** Tenda na Vila Barão Ragnar (`Vector2(1248, 810)`).
   * **Função:** Cumprimenta Daniel (`vendedor_ola`) e abre a `ShopModal` para negociar comidas, espadas, martelos e armaduras usando exclusivamente **cédulas de dinheiro (Notas)**.
3. **O Explorador (`explorador`):**
   * **Localização:** Presente nos acampamentos seguros das zonas de caçada:
     * **Floresta dos Ecos:** Orienta sobre Bola de Fogo `[1]` e os chefes locais (`explorador_floresta_1`, `explorador_floresta_2`).
     * **Cavernas e Minas:** Entrega/reforça Tornado `[2]` e Bomba de Água `[3]` contra os robôs (`explorador_caverna_1`, `explorador_caverna_2`).
     * **Castelo de Lunário:** Dá a dica final antes dos dragões (`explorador_castelo`).
