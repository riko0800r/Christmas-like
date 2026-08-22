-- lang.lua
local Lang = {}

Lang.current = "en"

local db = {
    ["pt-br"] = {
        -- MENU
        ["menu_play"]     = "Jogar",
        ["menu_tutorial"] = "Tutorial",
        ["menu_exit"]     = "Sair",
        ["intro_review"]  = "Ver intro denovo",
        ["menu_back"]     = "Voltar ao Menu",
        ["menu_continue"] = "Continuar",
        ["title_main"]    = "Christmas-like",
        ["menu_quem_fez"] = "Quem fez?",

        ["menu_options"] = "Configurações",
        ["menu_coop"] = "Coop Online",
        ["coop_title"] = "Multiplayer Cooperativo",
        ["coop_hint"] = "Hospedeie ou entre em uma sessão", 
        ["coop_host"] = "Hospedar",
        ["coop_join"] = "Conectar",
        ["coop_ready"] = "Estou pronto",
        ["coop_room"] = "Sala",
        ["coop_password"] = "Senha",
        ["opt_music"] = "Música",
        ["opt_sfx"] = "Efeitos",
        ["opt_timer"] = "Timer Speedrun: %s",
        ["opt_fullscreen"] = "Tela Cheia: %s",
        ["opt_lang"] = "Idioma: %s",
        ["opt_old_music"]="Musica antiga: %s",
        ["state_on"] = "LIGADO",
        ["state_off"] = "DESLIGADO",

        -- MENU DE MODS
        ["opt_mods"] = "Mods (%d)",
        ["mods_title"] = "Gerenciar Mods",
        ["mods_empty"] = "Nenhum mod encontrado.",
        ["mods_empty_hint"] = "Coloque pastas de mod em mods/ e reinicie o jogo.",
        ["mods_error"] = "Erro: %s",
        ["mods_disabled_by"] = "Desabilitado - por %s",
        ["mods_by"] = "por %s",
        ["mods_prev"] = "Ant",
        ["mods_next"] = "Prox",
        ["mods_restart_notice"] = "Reinicie o jogo para aplicar as mudanças.",
        ["mods_open_folder"] = "Abrir pasta de mods",
        
        -- QUEM FEZ?
        ["riko"]= "pixel art e programação por RIKO",
        ["magma"]= "musicas (OST INTEIRA) por MAGMAGUY",

        ["win_title"] = "VOCÊ VENCEU!",
        -- DIFICULDADE
        ["diff_select"] = "Escolha a dificuldade:",
        ["diff_easy"] = "Facil [Apenas para novatos]",
        ["diff_normal"] = "Normal [Experiencia padrão]",
        ["diff_hard"] = "Dificil [Chefes mais frequentes]",
        ["diff_boss"] = "Apenas Chefes [Boss Rush]",
        ["diff_insane"] = "Loucura [Acabe na onda 32]",
        ["diff_impossible"] = "Impossivel [Acabe na onda 64]",

        -- INTRO
        ["intro_1"] = "historia: você é uma rena do mal que quer destruir o mundo",
        ["intro_2"] = "mas as renas do bem, não gostaram disso",
        ["intro_3"] = "e decidiram lutar contra isso.",
        ["intro_4"] = "e então vocês irão lutar até o fim do natal.",
        ["intro_skip"] = "aperte X ou enter",

        ["mode_select_title"] = "Escolha o Modo de Jogo",
        ["mode_classic"] = "Clássico",
        ["mode_daily"] = "Desafio Diário",

        ["mode_seed"] = "Seed Personalizada",
        ["seed_instruction"] = "Digite uma seed (max 6 caracteres):",
        ["seed_confirm"] = "Confirmar",

        -- TUTORIAL
        ["tut_title"] = "=== TUTORIAL ===",
        ["tut_controls"] = "CONTROLES :",
        ["tut_move"] = "- Setas ou WASD : Mover",
        ["tut_confirm"] = "- X ou Enter : Confirmar",
        ["tut_obj_title"] = "OBJETIVOS :",
        ["tut_obj_1"] = "Sobreviva até a onda 16!",
        ["tut_obj_2"] = "Escolha recompensas entre ondas",
        ["tut_obj_3"] = "Fique mais forte a cada rodada!",

        -- GAMEPLAY HUD
        ["wave_display"] = "Onda : %d / %s",
        ["wave_infinite"] = "infinito",
        ["reset_hint"] = "R para resetar",
        ["game_over_msg"] = "e morreu.",
        ["win_msg_1"] = "Você sobreviveu ao Natal!",
        ["win_msg_2"] = "Agora, o que você fará?",
        ["end_opt_infinite"] = "Modo infinito",
        ["end_opt_finish"] = "Acabar com o mundo",

        -- STATS GAME OVER
        ["stat_weapons"] = "ARMAS",
        ["stat_effects"] = "EFEITOS",
        ["stat_time"] = "TEMPO: %ds",
        ["stat_total"] = "TOTAL: %d dmg",

        -- PERSONAGENS
        ["char_select_title"] = "ESCOLHA SEU PERSONAGEM",
        ["char_random"] = "Personagem Aleatorio",
        ["char_normal"] = "Rena Normal",
        ["char_normal_desc"] = "Começa com bloco de gelo\nbloco de gelo: varios tiros em forma circular",
        ["char_vital"] = "Rena vital",
        ["char_vital_desc"] = "Começa com Vitalidade\nVitalidade: ganha algumas vidas a cada alguns segundos",
        ["char_poison"] = "Rena Venenosa",
        ["char_poison_desc"] = "Começa com veneno mortal\nveneno mortal: dano a cada alguns segundo",
        ["char_fire"] = "Rena de Fogo",
        ["char_fire_desc"] = "Começa com fogo perigoso\nfogo perigoso: dano a cada alguns segundo",
        ["char_ice"] = "Rena de Gelo",
        ["char_ice_desc"] = "Começa com imobilizador\nImobilizador: deixa os inimigos mais lentos.",
        ["char_rock"] = "Rena de Pedra",
        ["char_rock_desc"] = "Começa com pedras do céu\ncaem pedras do céu e dão 3X o seu dano, mas a mira é bem ruim.",
        ["char_lava"] = "Rena Dourada",
        ["char_lava_desc"] = "Começa com Presente de ouro\nAnel ao redor da rena protegendo ela e atacando inimigos.",
        ["char_gift"] = "Presente Precioso",
        ["char_gift_desc"] = "Começa com Pedras preciosas\nJoga Muitas Pedras Preciosas para cima dando metade do seu dano",
        ["char_mystery"] = "Rena Misteriosa",
        ["char_mystery_desc"] = "Começa com 2 itens aleatórios\npode ter combinações imprevisíveis!",
        ["char_tree"]="Árvore de natal",
        ["char_tree_desc"]="Começa com guirlanda de espinhos\nAura circular de dano ao redor de você.",
        ["char_gift2"]="Presente ruim",
        ["char_gift2_desc"]="Começa com um bumerang natalino\nVai e volta deixando presentes na volta",
        
        ["char_atirador"]="Rena atiradora",
        ["char_atirador_desc"]="Começa com uma bola de neve\nbola de neve: tiro que segue inimigos",
        
        ["char_estrela_natalina"]="Presente Estrelado",
        ["char_estrela_natalina_desc"]="Começa com Chuva estrelada\nescolhe inimigos Aleatoriamente e faz chuver estrelas neles.",
        -- ITENS / RECOMPENSAS
        ["reward_choose"] = "Escolha sua recompensa:",
        ["item_life"] = "Vida",
        ["item_life_desc"] = "Aumenta a vida máxima!",
        ["item_life_stat"] = "Nível %d: %d -> %d vida",
        ["item_str"] = "Força",
        ["item_str_desc"] = "Aumenta o dano!",
        ["item_str_stat"] = "Nível %d: %.2f -> %.2f de dano",
        ["item_spd"] = "Rapidez",
        ["item_spd_desc"] = "Aumenta a velocidade!",
        ["item_spd_stat"] = "Nível %d: %.2f -> %.2f velocidade",
        ["item_new"] = "Novos itens",
        ["item_new_desc"] = "Regera as recompensas!",
        ["item_new_stat"] = "Troca as 3 opções atuais.",
        ["item_snow"] = "Bola de neve",
        ["item_snow_desc"] = "atira uma bola de neve que segue os inimigos!",
        ["item_snow_stat"] = "Nível %d | Dano: %.2f -> %.2f | Tempo: %.2fs -> %.2fs",
        ["item_ice"] = "Bloco de gelo",
        ["item_ice_desc"] = "Cria blocos de gelo em formato circular",
        ["item_ice_stat"] = "Nível %d | Dano: %.2f -> %.2f | Tempo: %.2fs -> %.2fs",
        ["item_rock"] = "Pedras do ceu",
        ["item_rock_desc"] = "Pedras que caem do céu (3x dano)!",
        ["item_rock_stat"] = "Nível %d | Dano: %.2f -> %.2f | Tempo: %.2fs -> %.2fs",
        ["item_psn"] = "Veneno mortal",
        ["item_psn_desc"] = "Dano venenoso contínuo!",
        ["item_psn_stat"] = "Nível %d | Dano: %.2f -> %.2f | Tempo: %.2fs -> %.2fs",
        ["item_fire"] = "Fogo perigoso",
        ["item_fire_desc"] = "Queima inimigos continuamente!",
        ["item_fire_stat"] = "Nível %d | Dano: %.2f -> %.2f | Tempo: %.2fs -> %.2fs",
        ["item_frz"] = "Imobilizador",
        ["item_frz_desc"] = "Congela e desacelera inimigos!",
        ["item_frz_stat"] = "Nível %d | Lentidão: %.0f%% -> %.0f%% | Tempo: %.2fs -> %.2fs",
        ["item_vit"] = "Vitalidade",
        ["item_vit_desc"] = "Recupera vida ao final de cada onda! (Não Aumenta vida maxima)",
        ["item_vit_stat"] = "Nível %d | Cura: %d -> %d por onda", 
        ["item_lava"] = "Presente de ouro",
        ["item_lava_desc"] = "Orbitam ao redor do jogador!",
        ["item_lava_stat"] = "Nível %d | Quantidade: %d -> %d | Dano: %.2f -> %.2f",
        ["item_gem"] = "Pedras Preciosas",
        ["item_gem_desc"] = "Múltiplos projeteis preciosos para cima e para baixo!",
        ["item_gem_stat"] = "Nível %d | Quantidade: %d -> %d | Dano: %.2f -> %.2f",

        ["item_sword"] = "Espada triângular",
        ["item_sword_desc"] = "Projetil que a cada ataque gira a rotação ao seu redor.",
        ["item_sword_stat"] = "Nível %d | Dano: %.2f -> %.2f | Tempo: %.2fs -> %.2fs",

        ["item_garlic"] = "Guirlanda de Espinhos",
        ["item_garlic_desc"] = "Aura que danifica inimigos próximos!",
        ["item_garlic_stat"] = "Nvl %d | Raio: %d | Dano: %.1f",
        
        ["item_boom"] = "Bumerangue Natalino",
        ["item_boom_desc"] = "Vai e volta deixando presentes explosivos na volta!",
        ["item_boom_stat"] = "Nvl %d | Cooldown: %.1fs",
        
        ["item_lifesteal"] = "Drenagem Natalina",
        ["item_lifesteal_desc"] = "Recupera vida baseado no dano causado!",
        ["item_lifesteal_stat"] = "Nvl %d | Cura: %.1f%% do dano",

        ["item_multishot"] = "Rajada Glacial",
        ["item_multishot_desc"] = "Chance de disparar múltiplos tiros!",
        ["item_multishot_stat"] = "Nível %d | Chance: %.0f%% → %.0f%% | Extra: %d → %d",

        ["item_explosion"] = "Presente Explosivo",
        ["item_explosion_desc"] = "Inimigos mortos explodem causando dano em área!",
        ["item_explosion_stat"] = "Nível %d | Dano: %.0f%% → %.0f%% do dano | Raio: %dpx → %dpx",

        ["item_star_name"]="Chuva Estrelada",
        ["item_star_desc"]="Faz chover estrelas em inimigos aleatórios!",
        ["item_star_stat"] = "Nvl %d | Quantidade: %.1fs",

        -- SINERGIAS
        ["synergy_ring_name"] = "Anel de Rena",
        ["synergy_ring_desc"] = "Cria renas que atiram bolas de neve!",
        ["synergy_ring_stat"] = "Renas Ativas | Dano: %.2f",
        ["synergy_rock_name"] = "Pedras Perseguidoras",
        ["synergy_rock_desc"] = "Pedras do céu que perseguem inimigos!",
        ["synergy_rock_stat"] = "Dano: %.2f",
        ["synergy_tox_name"] = "Combo Tóxico",
        ["synergy_tox_desc"] = "Área de dano ao redor de inimigos!",
        ["synergy_tox_stat"] = "Raio de dano tóxico",

        ["pause_title"]="PAUSADO",
        ["pause_sub"]  ="Aperte Esc para despausar o jogo.",
        
        ["menu_continue_run"] = "Continuar Partida (Onda %d)",
        ["menu_record"]       = "Melhor: Onda %d | Tempo: %s",
        ["menu_no_record"]    = "Sem Recorde",

        ["shop_title"] = "LOJA DE NATAL",
        ["shop_reroll"] = "Trocar itens: $%d",
        ["shop_free"] = "GRÁTIS",
        ["shop_sold"] = "VENDIDO",
        ["shop_poor"] = "Dinheiro insuficiente!",
        ["swap_title"] = "SLOTS DE ARMA CHEIOS",
        ["swap_subtitle"] = "Escolha uma arma para substituir:",
        ["hud_money"] = "$%d",

        -- RELÍQUIAS
        ["relic_greed"] = "Ganância",
        ["relic_greed_desc"] = "Inimigos soltam mais moedas, mas têm mais HP.",
        ["relic_coin_magnet"] = "Imã de Moedas",
        ["relic_coin_magnet_desc"] = "Moedas são puxadas de longe.",
        ["relic_boots"] = "Botas Mágicas",
        ["relic_boots_desc"] = "Aumenta velocidade permanentemente.",
        ["relic_glass"] = "Canhão de Vidro",
        ["relic_glass_desc"] = "Dobra o dano, mas reduz HP máximo.",
        ["relic_gold_luck_desc"]="Dobra a chance de drops raros e melhora recompensas",
        ["relic_gold_luck"]="Sorte Dourada",

        -- ITENS DE USO ÚNICO
        ["item_potion"] = "Poção de Vida",
        ["item_potion_desc"] = "Uso único: Cura 5 HP instantaneamente.",
        ["item_bomb"] = "Bomba de Natal",
        ["item_bomb_desc"] = "Uso único: Explode todos inimigos na tela.",

        -- CONQUISTAS
        ["menu_achievements"] = "Conquistas",
        ["achievements_title"] = "Conquistas",
        ["achievements_percent"] = "%d%% completo",
        ["achievements_empty"] = "Nenhuma conquista encontrada",
        ["achievements_prev"] = "< Ant",
        ["achievements_next"] = "Prox >",
        ["achievements_unlocks"] = "Libera: %s",

        ["char_locked"] = "Personagem bloqueado.",
        ["char_locked_hint"] = "Como desbloquear: %s",
        ["char_locked_label"] = "??? (bloqueado)",

        ["ach_first_wave_name"] = "Primeiros Passos",
        ["ach_first_wave_desc"] = "Sobreviva à primeira onda",
        ["ach_wave10_name"] = "Aquecendo",
        ["ach_wave10_desc"] = "Alcance a onda 10",
        ["ach_wave20_name"] = "Veterano",
        ["ach_wave20_desc"] = "Alcance a onda 20 (desbloqueia personagem)",
        ["ach_wave30_name"] = "Lenda",
        ["ach_wave30_desc"] = "Alcance a onda 30 (desbloqueia personagem)",
        ["ach_infinite_name"] = "Sem Fim",
        ["ach_infinite_desc"] = "Ative o modo infinito (desbloqueia personagem)",

        ["ach_first_victory_name"] = "Primeira Vitória",
        ["ach_first_victory_desc"] = "Vença uma run (desbloqueia personagem)",
        ["ach_five_victories_name"] = "Campeão",
        ["ach_five_victories_desc"] = "Vença 5 runs no total (desbloqueia personagem)",
        ["ach_no_damage_name"] = "Intocável",
        ["ach_no_damage_desc"] = "Vença uma run sem sofrer dano (desbloqueia personagem)",

        ["ach_kill100_name"] = "Caçador",
        ["ach_kill100_desc"] = "Derrote 100 inimigos no total",
        ["ach_kill1000_name"] = "Exterminador",
        ["ach_kill1000_desc"] = "Derrote 1000 inimigos no total (desbloqueia personagem)",
        ["ach_killboss_name"] = "Matador de Chefes",
        ["ach_killboss_desc"] = "Derrote um chefe",
        ["ach_dmg1000_name"] = "Poder Devastador",
        ["ach_dmg1000_desc"] = "Cause 1000 de dano numa run (desbloqueia personagem)",

        ["ach_gold500_name"] = "Bolso Cheio",
        ["ach_gold500_desc"] = "Acumule 500 de ouro numa run",
        ["ach_goldtotal_name"] = "Rico",
        ["ach_goldtotal_desc"] = "Ganhe 1000 de ouro no total (desbloqueia personagem)",
        ["ach_buy10_name"] = "Comprador",
        ["ach_buy10_desc"] = "Compre 10 itens na loja (desbloqueia personagem)",

        ["ach_relics3_name"] = "Colecionador",
        ["ach_relics3_desc"] = "Tenha 3 relíquias numa run",
        ["ach_relicsall_name"] = "Completista",
        ["ach_relicsall_desc"] = "Tenha todas as relíquias numa run (desbloqueia personagem)",

        ["ach_daily_name"] = "Desafio Diário",
        ["ach_daily_desc"] = "Jogue o modo diário (desbloqueia personagem)",
    },
    ["en"] = {
        -- MENU
        ["menu_play"]     = "Play",
        ["menu_tutorial"] = "Tutorial",
        ["menu_exit"]     = "Exit",
        ["intro_review"]  = "Intro again",
        ["menu_back"]     = "Back to Menu",
        ["menu_continue"] = "Continue",
        ["title_main"]    = "Christmas-like",
        ["menu_quem_fez"] = "Credits",

        ["menu_options"] = "Settings",
        ["menu_coop"] = "Coop Online",
        ["coop_title"] = "Cooperative Multiplayer",
        ["coop_hint"] = "Host or join a session",
        ["coop_host"] = "Host",
        ["coop_join"] = "Join",
        ["coop_ready"] = "I'm ready",
        ["coop_room"] = "Room",
        ["coop_password"] = "Password",
        ["opt_music"] = "Music",
        ["opt_sfx"] = "Sound Effects",
        ["opt_timer"] = "Speedrun Timer: %s",
        ["opt_fullscreen"] = "Fullscreen: %s",
        ["opt_lang"] = "Language: %s",
        ["opt_old_music"]="Old Music: %s",
        ["state_on"] = "ON",
        ["state_off"] = "OFF",

        -- MODS MENU
        ["opt_mods"] = "Mods (%d)",
        ["mods_title"] = "Manage Mods",
        ["mods_empty"] = "No mods found.",
        ["mods_empty_hint"] = "Put mod folders in mods/ and restart the game.",
        ["mods_error"] = "Error: %s",
        ["mods_disabled_by"] = "Disabled - by %s",
        ["mods_by"] = "by %s",
        ["mods_prev"] = "Prev",
        ["mods_next"] = "Next",
        ["mods_restart_notice"] = "Restart the game to apply changes.",
        ["mods_open_folder"] = "Open mods folder",
        
        -- CREDITS
        ["riko"]= "pixel art and programming by RIKO",
        ["magma"]= "music (ENTIRE OST) by MAGMAGUY",

        ["win_title"] = "YOU WON!",
        -- DIFFICULTY
        ["diff_select"] = "Choose difficulty:",
        ["diff_easy"] = "Easy [For newcomers]",
        ["diff_normal"] = "Normal [Standard experience]",
        ["diff_hard"] = "Hard [More frequent bosses]",
        ["diff_boss"] = "Boss Rush [Only bosses]",
        ["diff_insane"] = "Insane [Reach wave 32]",
        ["diff_impossible"] = "Impossible [Reach wave 64]",

        -- INTRO
        ["intro_1"] = "Story: You are an evil reindeer who wants to destroy the world",
        ["intro_2"] = "but the good reindeers, didn't like that",
        ["intro_3"] = "and decided to fight against it.",
        ["intro_4"] = "and then you will fight until the end of Christmas.",
        ["intro_skip"] = "press X or enter",

        -- TUTORIAL
        ["tut_title"] = "=== TUTORIAL ===",
        ["tut_controls"] = "CONTROLS:",
        ["tut_move"] = "- Arrows or WASD : Move",
        ["tut_confirm"] = "- X or Enter : Confirm",
        ["tut_obj_title"] = "OBJECTIVES:",
        ["tut_obj_1"] = "Survive until wave 16!",
        ["tut_obj_2"] = "Choose rewards between waves",
        ["tut_obj_3"] = "Get stronger every round!",

        -- GAMEPLAY HUD
        ["wave_display"] = "Wave : %d / %s",
        ["wave_infinite"] = "infinite",
        ["reset_hint"] = "R to reset",
        ["game_over_msg"] = "you died.",
        ["win_msg_1"] = "You survived Christmas!",
        ["win_msg_2"] = "Now, what will you do?",
        ["end_opt_infinite"] = "Infinite Mode",
        ["end_opt_finish"] = "End the World",

        -- STATS GAME OVER
        ["stat_weapons"] = "WEAPONS",
        ["stat_effects"] = "EFFECTS",
        ["stat_time"] = "TIME: %ds",
        ["stat_total"] = "TOTAL: %d dmg",

        -- CHARACTERS
        ["char_select_title"] = "CHOOSE YOUR CHARACTER",
        ["char_random"] = "Random Character",
        ["char_normal"] = "Normal Reindeer",
        ["char_normal_desc"] = "starts with ice block\nice block: circular shots",
        ["char_vital"] = "Vital Reindeer",
        ["char_vital_desc"] = "starts with Vitality\nVitality:after a few seconds gains lifes",
        ["char_poison"] = "Poison Reindeer",
        ["char_poison_desc"] = "starts with deadly poison\npoison: damage over time",
        ["char_fire"] = "Fire Reindeer",
        ["char_fire_desc"] = "starts with dangerous fire\nfire: burn damage over time",
        ["char_ice"] = "Ice Reindeer",
        ["char_ice_desc"] = "Starts with immobilizer\nslows enemies down.",
        ["char_rock"] = "Rock Reindeer",
        ["char_rock_desc"] = "Starts with Heaven Rocks\nrocks fall (3X dmg), bad aim.",
        ["char_lava"] = "Golden Reindeer",
        ["char_lava_desc"] = "Starts with Golden gifts\nRing protects and attacks enemies.",
        ["char_gift"] = "Precious Gift",
        ["char_gift_desc"] = "Starts with Precious Gems\nThrows gems upwards and ",
        ["char_mystery"] = "Mystery Reindeer",
        ["char_mystery_desc"] = "Starts with 2 random items\nunpredictable combinations!",
        
        ["char_tree"]="Christmas Tree",
        ["char_tree_desc"]="Starts with Spiked Wreath\nCircular aura of damage around the player.",

        ["char_gift2"]="Bad Gift",
        ["char_gift2_desc"]="Starts with Christmas Boomerang\nGoes and comes back leaving gifts on return.",

        ["char_atirador"]="Sniper Reindeer",
        ["char_atirador_desc"]="Starts with a snowball\nSnowball: a shot that follows enemies.",

        ["char_estrela_natalina"]="Starry Gift",
        ["char_estrela_natalina_desc"]="Starts with fallen stars\nMakes stars fall on random enemies!",

        -- ITEMS / REWARDS
        ["reward_choose"] = "Choose your reward:",
        ["item_life"] = "Health",
        ["item_life_desc"] = "Increases max health!",
        ["item_life_stat"] = "Level %d: %d -> %d HP",
        ["item_str"] = "Strength",
        ["item_str_desc"] = "Increases damage!",
        ["item_str_stat"] = "Level %d: %.2f -> %.2f dmg",
        ["item_spd"] = "Speed",
        ["item_spd_desc"] = "Increases movement speed!",
        ["item_spd_stat"] = "Level %d: %.2f -> %.2f speed",
        ["item_new"] = "New Items",
        ["item_new_desc"] = "Rerolls rewards!",
        ["item_new_stat"] = "Swaps current 3 options.",
        ["item_snow"] = "Snowball",
        ["item_snow_desc"] = "Shoot snowballs that follow enemies!",
        ["item_snow_stat"] = "Level %d | Dmg: %.2f -> %.2f | Time: %.2fs -> %.2fs",
        ["item_ice"] = "Ice Block",
        ["item_ice_desc"] = "Shoot ice blocks in a circular shape!",
        ["item_ice_stat"] = "Level %d | Dmg: %.2f -> %.2f | Time: %.2fs -> %.2fs",
        ["item_rock"] = "Heaven Rocks",
        ["item_rock_desc"] = "Rocks fall from sky (3x dmg)!",
        ["item_rock_stat"] = "Level %d | Dmg: %.2f -> %.2f | Time: %.2fs -> %.2fs",
        ["item_psn"] = "Deadly Poison",
        ["item_psn_desc"] = "Continuous poison damage!",
        ["item_psn_stat"] = "Level %d | Dmg: %.2f -> %.2f | Time: %.2fs -> %.2fs",
        ["item_fire"] = "Dangerous Fire",
        ["item_fire_desc"] = "Burns enemies continuously!",
        ["item_fire_stat"] = "Level %d | Dmg: %.2f -> %.2f | Time: %.2fs -> %.2fs",
        ["item_frz"] = "Immobilizer",
        ["item_frz_desc"] = "Freezes and slows enemies!",
        ["item_frz_stat"] = "Level %d | Slow: %.0f%% -> %.0f%% | Time: %.2fs -> %.2fs",
        ["item_vit"] = "Vitality",
        ["item_vit_desc"] = "Heals health at the end of each wave! (don't increase MAX HP)",
        ["item_vit_stat"] = "Level %d | Heal: %d -> %d per wave",
        ["item_lava"] = "Golden Gifts",
        ["item_lava_desc"] = "Orbit around the player!",
        ["item_lava_stat"] = "Level %d | Amount: %d -> %d | Dmg: %.2f -> %.2f",
        ["item_gem"] = "Precious Gems",
        ["item_gem_desc"] = "Multiple precious stones tossed up and down!",
        ["item_gem_stat"] = "Level %d | Amount: %d -> %d | Dmg: %.2f -> %.2f",
        ["item_sword"] = "Triangle Sword",
        ["item_sword_desc"] = "Projectile that rotates around you.",
        ["item_sword_stat"] = "Level %d | Dmg: %.2f -> %.2f | Time: %.2fs -> %.2fs",

        ["item_garlic"] = "Spiked Wreath",
        ["item_garlic_desc"] = "Aura that damages nearby enemies!",
        ["item_garlic_stat"] = "Lvl %d | Radius: %d | Dmg: %.1f",
        
        ["item_boom"] = "Christmas Boomerang",
        ["item_boom_desc"] = "Goes and comes back leaving gifts on return.",
        ["item_boom_stat"] = "Lvl %d | Cooldown: %.1fs",
        
        ["item_lifesteal"] = "Christmas Lifesteal",
        ["item_lifesteal_desc"] = "Recovers health based on damage dealt!",
        ["item_lifesteal_stat"] = "Lvl %d | Heal: %.1f%% of damage",

        ["item_multishot"] = "Glacial Burst",
        ["item_multishot_desc"] = "Chance to shoot multiple projectiles!",
        ["item_multishot_stat"] = "Level %d | Chance: %.0f%% → %.0f%% | Extra: %d → %d",

        ["item_explosion"] = "Explosive Gift",
        ["item_explosion_desc"] = "Dead enemies explode dealing area damage!",
        ["item_explosion_stat"] = "Level %d | Dmg: %.0f%% → %.0f%% of damage | Radius: %dpx → %dpx",

        ["item_star_name"]="Fallen Stars",
        ["item_star_desc"]="Makes stars fall on random enemies!",
        ["item_star_stat"] = "Lvl %d | Amount: %.1f",

        -- SYNERGIES
        ["synergy_ring_name"] = "Reindeer Ring",
        ["synergy_ring_desc"] = "Creates reindeers that shoot snowballs!",
        ["synergy_ring_stat"] = "Active Reindeers | Dmg: %.2f",
        ["synergy_rock_name"] = "Following Rocks",
        ["synergy_rock_desc"] = "Sky rocks that chase enemies!",
        ["synergy_rock_stat"] = "Dmg: %.2f",
        ["synergy_tox_name"] = "Toxic Combo",
        ["synergy_tox_desc"] = "Damage area around enemies!",
        ["synergy_tox_stat"] = "Toxic damage radius",

        ["pause_title"]="PAUSED",
        ["pause_sub"]  ="Press Esc to unpause the game.",
        
        ["menu_continue_run"] = "Continue Run (Wave %d)",
        ["menu_record"]       = "Best: Wave %d | Time: %s",
        ["menu_no_record"]    = "No Record",

        ["shop_title"] = "CHRISTMAS SHOP",
        ["shop_reroll"] = "Reroll Shop: $%d",
        ["shop_free"] = "FREE",
        ["shop_sold"] = "SOLD",
        ["shop_poor"] = "Not enough cash!",
        ["swap_title"] = "WEAPON SLOTS FULL",
        ["swap_subtitle"] = "Choose a weapon to replace:",
        ["hud_money"] = "$%d",

        -- RELICS
        ["relic_greed"] = "Greed",
        ["relic_greed_desc"] = "Enemies drop more coins, but have more HP.",
        ["relic_coin_magnet"] = "Coin Magnet",
        ["relic_coin_magnet_desc"] = "Coins are pulled from far away.",
        ["relic_boots"] = "Magic Boots",
        ["relic_boots_desc"] = "Increases movement speed permanently.",
        ["relic_glass"] = "Glass Cannon",
        ["relic_glass_desc"] = "Double your damage, but halve your max HP.",
        
        ["relic_gold_luck_desc"]="Doubles the chance of rare drops and improves rewards.",
        ["relic_gold_luck"]="Golden Luck",

        -- SINGLE USE ITEMS
        ["item_potion"] = "Health Potion",
        ["item_potion_desc"] = "One use: Heals 5 HP instantly.",
        ["item_bomb"] = "Christmas Bomb",
        ["item_bomb_desc"] = "One use: Explodes all enemies on screen.",

        ["mode_select_title"] = "Choose Game Mode",
        ["mode_classic"] = "Classic",
        ["mode_endless"] = "Endless Survival",
        ["mode_daily"] = "Daily Challenge",


        ["mode_seed"] = "Custom Seed",
        ["seed_instruction"] = "Enter a seed (max 6 chars):",
        ["seed_confirm"] = "Confirm",

        -- ACHIEVEMENTS
        ["menu_achievements"] = "Achievements",
        ["achievements_title"] = "Achievements",
        ["achievements_percent"] = "%d%% complete",
        ["achievements_empty"] = "No achievements found",
        ["achievements_prev"] = "< Prev",
        ["achievements_next"] = "Next >",
        ["achievements_unlocks"] = "Unlocks: %s",

        ["char_locked"] = "This character is locked.",
        ["char_locked_hint"] = "How to unlock: %s",
        ["char_locked_label"] = "??? (locked)",

        ["ach_first_wave_name"] = "First Steps",
        ["ach_first_wave_desc"] = "Survive the first wave",
        ["ach_wave10_name"] = "Warming Up",
        ["ach_wave10_desc"] = "Reach wave 10",
        ["ach_wave20_name"] = "Veteran",
        ["ach_wave20_desc"] = "Reach wave 20 (unlocks a character)",
        ["ach_wave30_name"] = "Legend",
        ["ach_wave30_desc"] = "Reach wave 30 (unlocks a character)",
        ["ach_infinite_name"] = "No End In Sight",
        ["ach_infinite_desc"] = "Enable endless mode (unlocks a character)",

        ["ach_first_victory_name"] = "First Victory",
        ["ach_first_victory_desc"] = "Win a run (unlocks a character)",
        ["ach_five_victories_name"] = "Champion",
        ["ach_five_victories_desc"] = "Win 5 runs total (unlocks a character)",
        ["ach_no_damage_name"] = "Untouchable",
        ["ach_no_damage_desc"] = "Win a run without taking damage (unlocks a character)",

        ["ach_kill100_name"] = "Hunter",
        ["ach_kill100_desc"] = "Defeat 100 enemies total",
        ["ach_kill1000_name"] = "Exterminator",
        ["ach_kill1000_desc"] = "Defeat 1000 enemies total (unlocks a character)",
        ["ach_killboss_name"] = "Boss Slayer",
        ["ach_killboss_desc"] = "Defeat a boss",
        ["ach_dmg1000_name"] = "Devastating Power",
        ["ach_dmg1000_desc"] = "Deal 1000 damage in a run (unlocks a character)",

        ["ach_gold500_name"] = "Full Pockets",
        ["ach_gold500_desc"] = "Accumulate 500 gold in a run",
        ["ach_goldtotal_name"] = "Wealthy",
        ["ach_goldtotal_desc"] = "Earn 1000 gold total (unlocks a character)",
        ["ach_buy10_name"] = "Shopper",
        ["ach_buy10_desc"] = "Buy 10 items from the shop (unlocks a character)",

        ["ach_relics3_name"] = "Collector",
        ["ach_relics3_desc"] = "Have 3 relics in a run",
        ["ach_relicsall_name"] = "Completionist",
        ["ach_relicsall_desc"] = "Have every relic in a run (unlocks a character)",

        ["ach_daily_name"] = "Daily Challenger",
        ["ach_daily_desc"] = "Play the daily mode (unlocks a character)",
    }
}

-- API PARA MODS: Lang.db expõe a tabela de traduções completa.
-- Um mod pode adicionar um idioma novo (Lang.db["es"] = {...}) ou
-- sobrescrever/adicionar chaves em um idioma existente
-- (Lang.db["pt-br"]["menu_play"] = "Jogar (mod)").
Lang.db = db

function Lang.setLanguage(lang)
    if db[lang] then Lang.current = lang end
end

function Lang.text(key, ...)
    local t = db[Lang.current][key]
    if not t then return "MISSING: " .. key end
    if #{...} > 0 then return string.format(t, ...) else return t end
end

return Lang