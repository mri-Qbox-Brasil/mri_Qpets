# mri_Qpets — Manual

Sistema de pets (fork do `keep-companion`, do Swkeep) com item de invocação, fome, sede, vida, XP/nível, variações de cor, truques e uma unidade K9 para a polícia.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Pets disponíveis](#pets-disponíveis)
5. [Itens](#itens)
6. [Comandos](#comandos)
7. [Menu do pet](#menu-do-pet)
8. [Ciclo de vida do pet](#ciclo-de-vida-do-pet)
9. [Unidade K9](#unidade-k9)
10. [Variações de cor](#variações-de-cor)
11. [Integrações](#integrações)
12. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
13. [Localização](#localização)
14. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qb-core` | Sim | Player, notificações, progressbar, callbacks, itens usáveis, comandos |
| `ox_inventory` | Sim | Toda a persistência do pet vive na metadata do item (`GetSlot`, `SetMetadata`, `RemoveItem`) |
| `ox_target` | Sim | Opções no pet: acariciar, cuidar, reanimar, dar água |
| `qb-menu` | Sim | Menu do pet (ações, truques, troca de controle) |
| `qb-input` | Sim | Formulários de renomear, coleira e customização |
| `oxmysql` | Sim | Carregado no `fxmanifest` |
| `qb-inventory` | Não | Só para a busca em veículo do K9 (`getGloveboxes` / `getTruck`). Definido em `Config.inventory_name` |
| `qb-hud` (ou equivalente) | Não | Acariciar o pet dispara `hud:server:RelieveStress` para aliviar estresse |

Este é um fork com conversão parcial para OX: o `ox_inventory` substituiu o inventário do QB, mas o resto do código continua dependendo do `qb-core`.

---

## Instalação

1. Copie a pasta `mri_Qpets` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qpets
   ```
3. **Cadastre os itens no `ox_inventory`** — os 15 itens de pet (`keepcompanion*`) e os 6 itens de cuidado. Os nomes exatos estão em [Itens](#itens). Os pets precisam ser `stack = false` (cada pet é único, identificado por um hash na metadata).
4. Copie as imagens de `inventory_images/` para a pasta de imagens do seu inventário (22 PNGs: um por pet e um por item de cuidado).
5. **Stream do modelo K9** — o modelo `a_c_k9` é um ped addon e **não é streamado por este recurso** (o `fxmanifest` não declara `files` nem `data_file`). A pasta `K9addon/` traz os arquivos prontos (`data/peds.meta` e `stream/`): mova-os para um recurso de stream próprio. Sem isso, o pet `keepcompanionk9unit` não spawna.
6. Adicione os pets e itens às lojas do seu servidor (`ox_inventory` shops ou `qb-shops`). O `keepcompanionk9unit` deve ficar em uma loja de acesso exclusivo da polícia.
7. Ajuste `Config.inventory_name` se o seu inventário de veículos não for o `qb-inventory` — o export de busca em porta-malas/porta-luvas do K9 depende disso.

Não há SQL a importar: todo o estado do pet é metadata do item no `ox_inventory`.

---

## Configuração

Arquivo: `config.lua`

### Geral

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.MaxActivePetsPetPlayer` | number | Sim | Máximo de pets ativos (spawnados) por jogador ao mesmo tempo |
| `Config.DataUpdateInterval` | number (s) | Sim | Intervalo entre os envios de atualização de vida e XP do pet ativo ao servidor. A thread do pet roda a cada 1 s e envia dados a cada `DataUpdateInterval` segundos |
| `Config.inventory_name` | string | Sim | Recurso de inventário usado nos exports de busca em veículo do K9. Padrão: `qb-inventory` |

### `Config.Settings`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `let_players_cutomize_their_pet_after_purchase` | bool | Sim | Abre o menu de nome/variação logo no primeiro uso do item |
| `callCompanionDuration` | number (s) | Sim | Duração da barra de progresso ao chamar o pet |
| `despawnDuration` | number (s) | Sim | Duração da barra de progresso ao guardar o pet |
| `itemUsageCooldown` | number (s) | Sim | Cooldown entre usos do item de pet, por jogador |
| `minHuntingAbilityLevel` | number | Sim | Nível mínimo para o pet poder caçar |
| `PetMiniMap` | tabela | Sim | Blip do pet: `showblip`, `sprite`, `colour`, `shortRange` |
| `chaseDistance` | number (m) | Sim | Distância máxima que o pet persegue um alvo antes de desistir |
| `chaseIndicator` | bool | Sim | Marcador sobre a cabeça do alvo caçado |
| `petMenuKeybind` | string | Sim | Tecla padrão do menu do pet. Padrão: `o` (o jogador pode remapear nas configurações do FiveM) |

### `Config.Balance`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `maximumLevel` | number | Sim | Nível máximo do pet. O cálculo de XP só é válido até 99 |
| `afk.afkTimerRestAfter` | number (s) | Sim | Após esse tempo de AFK o contador reinicia |
| `afk.wanderingInterval` | number (s) | Sim | Tempo de AFK até o pet começar a perambular ao redor do dono |
| `afk.animationInterval` | number (s) | Sim | Tempo de AFK até o pet começar a fazer animações |
| `petting_stress_relief` | number | Sim | Estresse aliviado ao acariciar o pet. Sorteado entre 12 e 24 no start do recurso |

### `Config.pets`

Lista de pets. Cada entrada:

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `name` | string | Sim | Nome do item no inventário |
| `model` | string | Sim | Modelo do ped |
| `maxHealth` | number | Sim | Vida máxima. **Valores ≤ 100 são tratados como morte** — não use valores baixos |
| `distinct` | string | Sim | `"yes <espécie>"` = pode caçar; `"no <espécie>"` = não pode. A espécie (`dog`, `cat`, `hen`, `rabbit`) escolhe as animações e o ícone do menu |
| `price` | number | Não | Presente apenas em uma entrada; não é lido pelo código do recurso |

### `Config.core_items`

Não altere as chaves da tabela (`food`, `collar`, `nametag`, `firstaid`, `groomingkit`, `waterbottle`) — só o `item_name` e as `settings`.

| Campo | Tipo | Descrição |
|---|---|---|
| `food.item_name` | string | Item de ração. Cada uso soma 50 de comida |
| `food.settings.duration` | number (s) | Duração da animação de alimentar |
| `collar.item_name` | string | Item de coleira (transferência de dono) |
| `collar.settings.duration` | number (s) | Duração da animação |
| `nametag.item_name` | string | Item de plaquinha (renomear) |
| `firstaid.item_name` | string | Kit de primeiros socorros |
| `firstaid.settings.heal_amount` | number (%) | Percentual da vida máxima curado por uso |
| `firstaid.settings.revive_heal_bonuses` | number | Vida acima de 100 com que o pet volta ao ser reanimado |
| `firstaid.settings.healing_duration_multiplier` | number | Multiplicador da duração ao curar |
| `firstaid.settings.revive_duration_multiplier` | number | Multiplicador da duração ao reanimar |
| `groomingkit.item_name` | string | Kit de tosa (troca a variação de cor) |
| `waterbottle.item_name` | string | Garrafa de água do pet |
| `waterbottle.settings.max_capacity` | number | Capacidade máxima da garrafa, em litros |
| `waterbottle.settings.water_bottle_refill_value` | number | Litros ganhos por uso — e quantos `water_bottle` são consumidos do inventário para encher |
| `waterbottle.settings.thirst_reduction_per_drinking` | number | Sede reduzida por gole |
| `waterbottle.settings.thirst_value_increase_per_tick` | number | Sede acumulada a cada ciclo de save (5 s) |

As chaves `usage_cycle`, `resting_cycle`, `overeat`, `max_overeat`, `weight_gain_by_evereat` e `max_weight_gain_by_evereat` em `food.settings` são placeholders do autor original e não têm efeito no código.

### `Config.k9`

| Campo | Tipo | Descrição |
|---|---|---|
| `k9.models` | tabela de strings | Modelos considerados K9. Só eles têm as ações de busca |
| `k9.illegal_items` | tabela de strings | Itens que o K9 detecta em pessoas e veículos |

---

## Pets disponíveis

| Item | Modelo | Vida máx. | Pode caçar |
|---|---|---|---|
| `keepcompanionwesty` | `A_C_Westy` | 150 | Não |
| `keepcompanionshepherd` | `A_C_shepherd` | 250 | Sim |
| `keepcompanionrottweiler` | `A_C_Rottweiler` | 300 | Sim |
| `keepcompanionretriever` | `A_C_Retriever` | 300 | Sim |
| `keepcompanionpug` | `A_C_Pug` | 150 | Não |
| `keepcompanionpoodle` | `A_C_Poodle` | 150 | Não |
| `keepcompanionmtlion2` | `A_C_Panther` | 350 | Sim |
| `keepcompanionmtlion` | `A_C_MtLion` | 350 | Sim |
| `keepcompanioncat` | `A_C_Cat_01` | 150 | Não |
| `keepcompanionhusky` | `A_C_Husky` | 350 | Sim |
| `keepcompanionhen` | `A_C_Hen` | 350 | Não |
| `keepcompanionrabbit` | `A_C_Rabbit_01` | 125 | Não |
| `keepcompanioncoyote` | `A_C_Coyote` | 170 | Não |
| `keepcompanionrat` | `A_C_Rat` | 150 | Não |
| `keepcompanionk9unit` | `a_c_k9` | 200 | Sim |

Todos são itens usáveis: o primeiro uso inicializa o pet (gera hash, nome, gênero, variação); os usos seguintes chamam ou guardam o pet.

---

## Itens

| Item | Efeito ao usar |
|---|---|
| `petfood` | Alimenta o pet ativo: +50 de comida |
| `collarpet` | Abre o formulário de transferência de dono (informe o ID do novo dono). Consome a coleira |
| `petnametag` | Abre o formulário para renomear o pet. Consome a plaquinha |
| `firstaidforpet` | Não faz nada ao ser usado diretamente — as ações **Cuidar** e **Reanimar** estão no `ox_target` sobre o pet e consomem o item |
| `petgroomingkit` | Abre o menu de variação de cor do pet. Consome o kit |
| `petwaterbottleportable` | Enche a garrafa, consumindo `water_bottle_refill_value` unidades do item `water_bottle` do inventário |

O item `water_bottle` (água comum do servidor) precisa existir: é ele que enche a garrafa do pet.

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/addpet [item]` | admin | Adiciona um item de pet ao próprio inventário |
| `/addItem [item]` | admin | Adiciona um item qualquer ao próprio inventário |
| `/renamePet [nome]` | admin | Abre o fluxo de renomear o pet |

Todos são registrados via `QBCore.Commands.Add` com a permissão `admin`.

O menu do pet não tem comando: é aberto pela tecla mapeada em `Config.Settings.petMenuKeybind` (padrão `o`), registrada com `RegisterKeyMapping`. O menu não abre se o jogador estiver algemado, no menu de pausa, ou caído (a menos que seja polícia ou paramédico).

---

## Menu do pet

Aberto pela tecla do keybind, exige pelo menos um pet ativo.

### Ações

| Ação | Descrição |
|---|---|
| Seguir | O pet passa a seguir o dono |
| Caçar | Entra no modo de mira: aponte a câmera e pressione **E** para o pet atacar o ped alvo. Exige `distinct = "yes ..."` e nível acima de `minHuntingAbilityLevel`. Se o alvo fugir além de `chaseDistance`, o pet desiste |
| Caçar e trazer | Igual à caça, mas quando o alvo morre o pet prende o corpo na boca e o arrasta de volta até o dono |
| Ir até lá | Aponte a câmera e pressione **E**: o pet vai até o ponto marcado |
| Esperar | Limpa as tasks do pet |
| Entrar no carro | O pet entra no primeiro assento livre do veículo do dono (exige o dono dentro do carro e o pet a menos de 8 m) |
| Revistar pessoa | O pet vai até o jogador mais próximo e revista o inventário dele atrás dos `illegal_items`. **Exige job `police` em serviço** |
| Revistar carro | Busca no porta-luvas e no porta-malas do veículo mais próximo. **Só aparece para o job `police` com um pet K9** |

"Revistar pessoa" aparece no menu para todos, mas a função recusa quem não for `police` em serviço.

### Truques

Implorar, Dar a pata e Fingir-se de morto.

### Trocar de controle

Alterna qual pet ativo recebe os comandos do menu, quando `MaxActivePetsPetPlayer` for maior que 1.

### Opções no `ox_target` (mirando o pet)

| Opção | Condição |
|---|---|
| Acariciar | Pet vivo — dispara `hud:server:RelieveStress` |
| Cuidar | Pet vivo — consome `firstaidforpet` e cura `heal_amount`% da vida máxima |
| Reanimar | Pet morto — consome `firstaidforpet` e devolve o pet com `100 + revive_heal_bonuses` de vida |
| Dar água | Pet vivo — consome água da garrafa e reduz a sede |

---

## Ciclo de vida do pet

Todo o estado do pet fica na **metadata do item** no `ox_inventory` e é salvo pelo servidor a cada **5 segundos** enquanto o pet está spawnado.

| Campo da metadata | Descrição |
|---|---|
| `hash` | Identificador único do pet, gerado na inicialização |
| `name` | Nome do pet (gerado aleatoriamente no primeiro uso) |
| `gender` | Gênero, sorteado na inicialização |
| `age` | Idade em segundos. Cresce 5 s por ciclo de save, até o teto de 10 dias |
| `food` | Comida (0-100). Cai 1 por ciclo |
| `thirst` | Sede (0-100). Sobe `thirst_value_increase_per_tick` por ciclo |
| `health` | Vida atual |
| `level` / `XP` | Nível e experiência |
| `owner` | `charinfo` do dono. Usado para checar se o jogador é o dono legítimo |
| `variation` | Nome da variação de cor |

**Vida ≤ 100 significa pet morto.** É por isso que `maxHealth` na config nunca deve ser baixa: os 100 primeiros pontos de vida do GTA são a "faixa morta" e o script trata qualquer valor abaixo disso como zero.

Comida em 0 drena 0,2 de vida por ciclo; sede em 100 drena 0,5 por ciclo. Quando a vida chega em 100 por fome ou sede, o pet é morto à força (`keep-companion:client:forceKill`).

Se um jogador tentar usar um item de pet cujo `owner.phone` não bate com o dele, o pet é spawnado e imediatamente removido, e ele recebe a notificação "Você não é o dono deste pet".

---

## Unidade K9

O recurso tem duas ações de busca, ambas exigindo o job `police` em serviço:

- **Revistar pessoa** — o servidor varre o inventário do jogador mais próximo procurando os itens de `Config.k9.illegal_items`. Essa ação **não** checa o modelo do pet: qualquer pet de um policial em serviço pode fazê-la.
- **Revistar carro** — **exclusiva do K9.** O pet caminha até dois pontos do veículo (lateral e traseira) e checa porta-luvas e porta-malas via os exports `getGloveboxes` e `getTruck` do recurso em `Config.inventory_name`. Encontrando item ilegal, late e faz a animação de alerta; senão, senta. A opção só aparece no menu se o jogador for `police` **e** o pet ativo for um dos modelos de `Config.k9.models`.

O modelo do K9 precisa ser streamado separadamente — ver [Instalação](#instalação).

---

## Variações de cor

`shared/shared.lua` mapeia, por modelo, os nomes de variação e os `componentId` / `drawableId` / `textureId` correspondentes. Exemplos: `A_C_Husky` tem `dark`, `brown` e `white`; `a_c_k9` tem `GoldBlack`, `WhiteBrown`, `BlackBrown` e `Black`; `A_C_Poodle` tem só `white`.

Uma variação é sorteada na inicialização do pet e gravada na metadata. Depois, o `petgroomingkit` permite trocá-la pela lista de variações do modelo.

Para adicionar uma variação nova, acrescente a entrada na tabela `PetVariation` do modelo. A função utilitária `variationTester(ped, componentId)` no mesmo arquivo imprime no console todas as combinações válidas de drawable/texture de um ped.

---

## Integrações

### ox_inventory

É a fonte da verdade do estado do pet. O recurso lê e escreve a metadata do slot (`GetSlot`, `SetMetadata`, `GetInventoryItems`) e remove itens consumíveis (`RemoveItem`). Os pets precisam ser cadastrados como itens não empilháveis.

### ox_target

Registra as quatro opções no ped do pet (`addEntity` com o net ID) no momento em que ele é spawnado.

### qb-inventory

Usado apenas pela busca em veículo do K9, via os exports `getGloveboxes(plate)` e `getTruck(plate)`. O recurso é resolvido por `Config.inventory_name`, então qualquer inventário que exponha esses dois exports funciona.

### qb-hud

Acariciar o pet dispara `TriggerServerEvent('hud:server:RelieveStress', Config.Balance.petting_stress_relief)`. Sem um recurso que escute esse evento, o carinho apenas não alivia estresse — nada quebra.

---

## Entrypoints para outros recursos

### Evento `keep-companion:client:callCompanion`

Faz o client spawnar um pet. É o evento que o servidor dispara quando o jogador usa o item.

```lua
TriggerClientEvent('keep-companion:client:callCompanion', src, model, hostileTowardPlayer, item)
```

### Evento `keep-companion:client:despawn`

Guarda o pet. Com `revive = true`, o pet é removido sem a barra de progresso (usado pelo revive, pela tosa e pela troca de dono).

```lua
TriggerClientEvent('keep-companion:client:despawn', src, item, revive)
```

### Evento `keep-companion:client:forceKill`

Mata o pet imediatamente, com um motivo. O servidor usa com `'hunger'` quando a fome zera a vida.

```lua
TriggerClientEvent('keep-companion:client:forceKill', src, hash, reason)
```

### Callback `keep-companion:server:search_inventory`

Retorna `true` se o jogador com o ID informado carrega algum item de `Config.k9.illegal_items`.

```lua
QBCore.Functions.TriggerCallback('keep-companion:server:search_inventory', function(found) end, targetId)
```

### Callback `keep-companion:server:search_vehicle`

Retorna `true` se o porta-luvas (`key = 1`) ou o porta-malas (`key = 2`) da placa informada tem item ilegal.

```lua
QBCore.Functions.TriggerCallback('keep-companion:server:search_vehicle', function(found) end, { key = 1, plate = plate })
```

### Evento `keep-companion:server:onPlayerUnload`

Marca os pets de um jogador como despawnados. Deve ser disparado no logout.

---

## Localização

As strings vêm do sistema de locale do `qb-core` (`@qb-core/shared/locale.lua`), com o objeto global `Lang`. Os arquivos ficam em `locales/`:

- `pt-br.lua` — português do Brasil (**ativo**)
- `en.lua` — inglês

O idioma **não** é escolhido por convar: o `fxmanifest.lua` carrega diretamente `locales/pt-br.lua`. Para usar inglês, troque essa linha no `shared_scripts` do manifest por `locales/en.lua`.

Parte das strings do menu e das notificações está fixa no código (em português), fora dos arquivos de locale.

O `shared/badwords.lua` traz a lista de palavras bloqueadas na hora de nomear um pet.

---

## Estrutura de arquivos

```
mri_Qpets/
├── client/
│   ├── client.lua       — spawn/despawn, opções do ox_target, alimentar/beber/curar, thread AFK, dados do pet ativo
│   ├── functions.lua    — lógica de caça e perseguição, blips, spawn location, animações auxiliares
│   ├── menu.lua         — keybind, menus (ações, truques, troca de controle), busca do K9
│   ├── animator.lua     — dicionários e sequências de animação por espécie
│   └── c_util.lua       — utilitários de client
├── server/
│   ├── server.lua       — classe Pet, itens usáveis, spawn/despawn, revive, loop de save, comandos
│   └── functions.lua    — inicialização do item, gerador de nomes, XP/nível, fome/sede, troca de dono, cooldown
├── shared/
│   ├── shared.lua       — tabela PetVariation (variações de cor por modelo)
│   ├── util.lua         — helpers compartilhados
│   └── badwords.lua     — palavras bloqueadas em nomes de pet
├── locales/
│   ├── pt-br.lua        — carregado pelo fxmanifest
│   └── en.lua           — disponível, não carregado
├── config.lua           — pets, itens, balanceamento, settings, K9
├── inventory_images/    — 22 PNGs (um por pet e por item) para copiar no inventário
├── K9addon/             — ped addon a_c_k9 (data/peds.meta + stream/); precisa ir para um recurso de stream próprio
└── fxmanifest.lua
```
