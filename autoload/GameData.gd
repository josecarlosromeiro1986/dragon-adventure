extends Node

## Base de dados estática de armas, armaduras, comidas, magias, bestiário e zonas do reino.

## Retorna as dimensões do mapa atual a partir da cena ou usa o tamanho padrão Fenaky.
static func get_map_bounds(scene: Node) -> Vector2:
	if is_instance_valid(scene) and "map_width" in scene and "map_height" in scene:
		return Vector2(float(scene.map_width), float(scene.map_height))
	return Vector2(2048.0, 1152.0)

## Retorna a versão atual configurada em ProjectSettings (fonte única de versionamento).
static func get_game_version() -> String:
	var ver := str(ProjectSettings.get_setting("application/config/version", "1.0.0")).strip_edges()
	return ver if ver != "" else "1.0.0"

# Armas: 2 classes (Espada e Martelo) x 4 tiers (Madeira, Pedra, Ouro, Diamante)
const WEAPONS = {
	"sword_wood": {
		"id": "sword_wood",
		"name": "Espada de Madeira",
		"type": "sword",
		"tier": 1,
		"damage": 12,
		"cooldown": 0.35,
		"crit_rate": 0.05,
		"price": 0, # Arma inicial
		"desc": "Espada rústica entalhada na Vila Barão Ragnar."
	},
	"sword_stone": {
		"id": "sword_stone",
		"name": "Espada de Pedra",
		"type": "sword",
		"tier": 2,
		"damage": 25,
		"cooldown": 0.35,
		"crit_rate": 0.10,
		"price": 150,
		"desc": "Lâmina afiada feita de pedras da floresta."
	},
	"sword_gold": {
		"id": "sword_gold",
		"name": "Espada de Ouro",
		"type": "sword",
		"tier": 3,
		"damage": 55,
		"cooldown": 0.30,
		"crit_rate": 0.25,
		"price": 600,
		"desc": "Forjada com ouro das minas. Alta chance de acerto crítico."
	},
	"sword_diamond": {
		"id": "sword_diamond",
		"name": "Espada de Diamante",
		"type": "sword",
		"tier": 4,
		"damage": 120,
		"cooldown": 0.28,
		"crit_rate": 0.35,
		"price": 1800,
		"desc": "Lâmina lendária cristalina de poder devastador."
	},
	"hammer_wood": {
		"id": "hammer_wood",
		"name": "Martelo de Madeira",
		"type": "hammer",
		"tier": 1,
		"damage": 20,
		"cooldown": 0.65,
		"crit_rate": 0.05,
		"stun_chance": 0.20,
		"price": 50,
		"desc": "Martelo pesado que esmaga defesas e atordoa."
	},
	"hammer_stone": {
		"id": "hammer_stone",
		"name": "Martelo de Pedra",
		"type": "hammer",
		"tier": 2,
		"damage": 45,
		"cooldown": 0.60,
		"crit_rate": 0.10,
		"stun_chance": 0.25,
		"price": 200,
		"desc": "Bloco maciço de pedra capaz de quebrar carapaças."
	},
	"hammer_gold": {
		"id": "hammer_gold",
		"name": "Martelo de Ouro",
		"type": "hammer",
		"tier": 3,
		"damage": 95,
		"cooldown": 0.55,
		"crit_rate": 0.20,
		"stun_chance": 0.35,
		"price": 750,
		"desc": "Martelo dourado reluzente de impacto sísmico."
	},
	"hammer_diamond": {
		"id": "hammer_diamond",
		"name": "Martelo de Diamante",
		"type": "hammer",
		"tier": 4,
		"damage": 210,
		"cooldown": 0.50,
		"crit_rate": 0.30,
		"stun_chance": 0.50,
		"price": 2200,
		"desc": "O supremo destruidor de máquinas e carapaças dracônicas."
	}
}

# Armaduras: 4 Tiers
const ARMORS = {
	"none": {
		"id": "none",
		"name": "Roupas Simples",
		"tier": 0,
		"defense_pct": 0.0,
		"price": 0,
		"desc": "Camisa e calça simples do menino Daniel."
	},
	"armor_wood": {
		"id": "armor_wood",
		"name": "Armadura de Madeira",
		"tier": 1,
		"defense_pct": 0.10,
		"price": 80,
		"desc": "Placas leves de carvalho rústico."
	},
	"armor_stone": {
		"id": "armor_stone",
		"name": "Armadura de Pedra",
		"tier": 2,
		"defense_pct": 0.25,
		"price": 250,
		"desc": "Couraça de pedras polidas das cavernas."
	},
	"armor_gold": {
		"id": "armor_gold",
		"name": "Armadura de Ouro",
		"tier": 3,
		"defense_pct": 0.45,
		"price": 900,
		"desc": "Armadura dourada resplandecente que deflete golpes."
	},
	"armor_diamond": {
		"id": "armor_diamond",
		"name": "Armadura de Diamante",
		"tier": 4,
		"defense_pct": 0.70,
		"price": 2400,
		"desc": "A lendária couraça prismática que dissipa o dano dos dragões."
	}
}

# Raridades por Tier (usadas em Inventário, Loja, HUD e Efeitos de Combate)
const RARITIES = {
	0: {
		"id": "basic",
		"name": "Básico",
		"color": Color("#A89F91"),
		"accent": Color("#DED6C8"),
		"hex": "#A89F91",
		"aura_amount": 0,
		"slash_width": 4.5,
		"spark_count": 3
	},
	1: {
		"id": "common",
		"name": "Comum",
		"color": Color("#D9A066"),
		"accent": Color("#F5DFC2"),
		"hex": "#C88A4B",
		"aura_amount": 0,
		"slash_width": 5.5,
		"spark_count": 4
	},
	2: {
		"id": "uncommon",
		"name": "Incomum",
		"color": Color("#7CC6FE"),
		"accent": Color("#E0F3FF"),
		"hex": "#5BA8E6",
		"aura_amount": 5,
		"slash_width": 7.0,
		"spark_count": 7
	},
	3: {
		"id": "rare",
		"name": "Raro",
		"color": Color("#FFD700"),
		"accent": Color("#FFF7B2"),
		"hex": "#E6B800",
		"aura_amount": 9,
		"slash_width": 9.0,
		"spark_count": 11
	},
	4: {
		"id": "legendary",
		"name": "Lendário",
		"color": Color("#00F0FF"),
		"accent": Color("#E6FFFF"),
		"hex": "#00D8E6",
		"aura_amount": 15,
		"slash_width": 11.5,
		"spark_count": 16
	}
}

static func get_rarity(tier: int) -> Dictionary:
	return RARITIES.get(clampi(tier, 0, 4), RARITIES[1])

# Comidas de Cura
const FOODS = {
	"apple": {
		"id": "apple",
		"name": "Maçã Silvestre",
		"heal": 30,
		"price": 15,
		"desc": "Fruta colhida na floresta. Cura 30 HP."
	},
	"bread": {
		"id": "bread",
		"name": "Pão da Vila",
		"heal": 75,
		"price": 35,
		"desc": "Pão fresco assado na Vila Barão Ragnar. Cura 75 HP."
	},
	"meat": {
		"id": "meat",
		"name": "Carne Assada",
		"heal": 180,
		"price": 80,
		"desc": "Refeição substancial para enfrentar grandes chefes. Cura 180 HP."
	}
}

# Poderes Mágicos Elementais (3 magias)
const SPELLS = {
	"fireball": {
		"id": "fireball",
		"key": "1",
		"name": "Bola de Fogo",
		"element": "fire",
		"mana_cost": 15,
		"cooldown": 3.0,
		"damage": 45,
		"desc": "Projétil de calor ardente. x2 SUPER EFETIVO em Zumbis, Lobisomem e Toupeiras."
	},
	"tornado": {
		"id": "tornado",
		"key": "2",
		"name": "Tornado",
		"element": "wind",
		"mana_cost": 20,
		"cooldown": 5.0,
		"damage": 60,
		"desc": "Vórtice giratório que atrai e atordoa. x2 SUPER EFETIVO em Esqueletos e Fantasmas."
	},
	"water_bomb": {
		"id": "water_bomb",
		"key": "3",
		"name": "Bomba de Água",
		"element": "water",
		"mana_cost": 25,
		"cooldown": 6.0,
		"damage": 90,
		"desc": "Explosão líquida em área. x2 SUPER EFETIVO em Robôs, Robô Toupeira, Robô Aranha e Dragão."
	}
}

# Fraquezas Elementais: retorna o multiplicador de dano (2.0 se vulnerável, 1.0 se normal)
static func get_elemental_multiplier(spell_element: String, monster_id: String) -> float:
	match spell_element:
		"fire":
			if monster_id in ["zumbi", "lobisomem", "toupeira", "toupeira_serra", "espectro_slime"]:
				return 2.0
		"wind":
			if monster_id in ["esqueleto", "fantasma", "espectro_slime"]:
				return 2.0
		"water":
			if monster_id in ["robo", "robo_toupeira_serra", "robo_aranha", "dragao"]:
				return 2.0
	return 1.0

# Bestiário Completo: 7 Monstros Comuns + 6 Chefes
const MONSTERS = {
	# Monstros Comuns
	"toupeira": {
		"name": "Toupeira",
		"max_hp": 40,
		"damage": 8,
		"speed": 65.0,
		"xp": 15,
		"cash_min": 5,
		"cash_max": 15,
		"is_boss": false,
		"color": Color("#8B5A2B")
	},
	"zumbi": {
		"name": "Zumbi",
		"max_hp": 65,
		"damage": 12,
		"speed": 45.0,
		"xp": 25,
		"cash_min": 10,
		"cash_max": 25,
		"is_boss": false,
		"color": Color("#3B7A57")
	},
	"esqueleto": {
		"name": "Esqueleto",
		"max_hp": 55,
		"damage": 14,
		"speed": 75.0,
		"xp": 30,
		"cash_min": 15,
		"cash_max": 30,
		"is_boss": false,
		"color": Color("#DCDCDC")
	},
	"humano_minerador": {
		"name": "Humano Minerador",
		"max_hp": 90,
		"damage": 18,
		"speed": 60.0,
		"xp": 50,
		"cash_min": 25,
		"cash_max": 50,
		"is_boss": false,
		"color": Color("#CD853F")
	},
	"robo": {
		"name": "Robô Patrulheiro",
		"max_hp": 115,
		"damage": 22,
		"speed": 55.0,
		"xp": 75,
		"cash_min": 40,
		"cash_max": 75,
		"is_boss": false,
		"color": Color("#708090")
	},
	"fantasma": {
		"name": "Fantasma",
		"max_hp": 115,
		"damage": 26,
		"speed": 80.0,
		"xp": 120,
		"cash_min": 70,
		"cash_max": 125,
		"is_boss": false,
		"color": Color("#E0FFFF")
	},
	"espectro_slime": {
		"name": "Espectro de Slime",
		"max_hp": 145,
		"damage": 28,
		"speed": 72.0,
		"xp": 145,
		"cash_min": 85,
		"cash_max": 145,
		"is_boss": false,
		"color": Color("#A855F7")
	},

	# Chefes e Sub-Chefes
	"lobisomem": {
		"name": "Lobisomem (Sub-Chefe)",
		"max_hp": 300,
		"damage": 25,
		"speed": 95.0,
		"xp": 200,
		"cash_min": 150,
		"cash_max": 250,
		"is_boss": true,
		"color": Color("#4A4A4A")
	},
	"toupeira_serra": {
		"name": "Toupeira Serra (Chefe)",
		"max_hp": 550,
		"damage": 35,
		"speed": 70.0,
		"xp": 450,
		"cash_min": 350,
		"cash_max": 500,
		"is_boss": true,
		"color": Color("#A0522D")
	},
	"robo_toupeira_serra": {
		"name": "Robô Toupeira Serra (Sub-Chefe)",
		"max_hp": 800,
		"damage": 45,
		"speed": 75.0,
		"xp": 700,
		"cash_min": 600,
		"cash_max": 900,
		"is_boss": true,
		"color": Color("#4682B4")
	},
	"robo_aranha": {
		"name": "Robô Aranha (Chefe)",
		"max_hp": 1300,
		"damage": 60,
		"speed": 65.0,
		"xp": 1200,
		"cash_min": 1000,
		"cash_max": 1500,
		"is_boss": true,
		"color": Color("#2F4F4F")
	},
	"dragao": {
		"name": "O Dragão (Sub-Chefe)",
		"max_hp": 2600,
		"damage": 80,
		"speed": 85.0,
		"xp": 3200,
		"cash_min": 2400,
		"cash_max": 3200,
		"is_boss": true,
		"color": Color("#B22222")
	},
	"lunario": {
		"name": "Lunário, o Deus Dragão (Chefe Final)",
		"max_hp": 5200,
		"damage": 105,
		"speed": 90.0,
		"xp": 6000,
		"cash_min": 5000,
		"cash_max": 8000,
		"is_boss": true,
		"color": Color("#9370DB")
	}
}

# Zonas de Caçada e Mapas
const WORLDS = {
	"vila": {
		"id": "vila",
		"name": "Vila Barão Ragnar",
		"type": "safe_hub",
		"desc": "A última vila viva. Zona segura com comércio e histórias.",
		"color_bg": Color("#3B5323"),
		"monsters": [],
		"sub_boss": "",
		"boss": ""
	},
	"floresta": {
		"id": "floresta",
		"name": "Floresta dos Ecos",
		"type": "hunt_zone",
		"desc": "Ruínas cobertas por mato denso e animais corrompidos.",
		"color_bg": Color("#2E4F2E"),
		"monsters": ["toupeira", "zumbi", "esqueleto"],
		"sub_boss": "lobisomem",
		"boss": "toupeira_serra",
		"kills_to_boss": 8,
		"next_world": "caverna"
	},
	"caverna": {
		"id": "caverna",
		"name": "Cavernas e Minas",
		"type": "hunt_zone",
		"desc": "Minas profundas com maquinários de escavação a vapor.",
		"color_bg": Color("#282828"),
		"monsters": ["humano_minerador", "robo", "toupeira"],
		"sub_boss": "robo_toupeira_serra",
		"boss": "robo_aranha",
		"kills_to_boss": 12,
		"next_world": "castelo"
	},
	"castelo": {
		"id": "castelo",
		"name": "Castelo de Lunário",
		"type": "hunt_zone",
		"desc": "A fortaleza gótica flutuante do Deus Dragão.",
		"color_bg": Color("#1A1124"),
		"monsters": ["fantasma", "robo", "esqueleto", "espectro_slime"],
		"sub_boss": "dragao",
		"boss": "lunario",
		"kills_to_boss": 15,
		"next_world": "cabana"
	},
	"cabana": {
		"id": "cabana",
		"name": "Cabana Inimiga Distante",
		"type": "epilogue",
		"desc": "O cativeiro isolado onde o Barão Ragnar está aprisionado.",
		"color_bg": Color("#1C2526"),
		"monsters": [],
		"sub_boss": "",
		"boss": ""
	}
}
