class_name Camadas
extends RefCounted

## Camadas de física do projeto (valores de bitmask para collision_layer / collision_mask).

const PLAYER: int = 1 << 0            # 1 - corpo do player
const TERRENO: int = 1 << 1           # 2 - chão, paredes, paredes de teia
const ATAQUE_PLAYER: int = 1 << 2     # 3 - golpe do canudo, Jabussíntese
const INIMIGOS: int = 1 << 3          # 4 - corpos e hurtboxes de inimigos e chefes
const ITENS: int = 1 << 4             # 5 - coletáveis
const DANO_INIMIGO: int = 1 << 5      # 6 - hitboxes e projéteis de inimigos
const PLATAFORMA_VAZADA: int = 1 << 6 # 7 - plataformas one-way (agachar + pular desce)

## Tudo em que um corpo que anda se apoia.
const CHAO: int = TERRENO | PLATAFORMA_VAZADA
