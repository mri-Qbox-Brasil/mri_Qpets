local Translations = {
    -- Notificações gerais
    error = {
        no_pet_under_control = 'Pelo menos um pet deve estar sob seu controle',
        badword_inside_pet_name = 'Não dê esse nome ao seu pet!',
        more_than_one_word_as_name = 'Você não pode usar tantas palavras no nome do seu pet!',
        failed_to_start_procces = 'Falha ao iniciar o processo!',
        failed_to_find_pet = 'Não foi possível encontrar seu pet!',
        could_not_do_that = 'Não foi possível fazer isso',
        string_type = 'Tipo de nome incorreto (apenas string)!',
        not_enough_first_aid = 'Você precisa de primeiros socorros para fazer isso!',
        reached_max_allowed_pet = 'Você não pode ter mais do que %s pets ativos!',
        failed_to_validate_name = 'Não conseguimos validar esse nome, tente outro!',
        failed_to_rename = 'Falha ao renomear: %s',
        failed_to_rename_same_name = 'O nome anterior é igual ao novo: %s',
        your_pet_is_dead = 'Seu pet está morto, tente novamente quando ele estiver vivo',
        your_pet_died_by = 'Seu pet morreu por %s',
        not_owner_of_pet = 'Você não é o dono deste pet',

        failed_to_remove_item_from_inventory = 'Falha ao remover do seu inventário',
        failed_to_transfer_ownership_same_owner = 'Você não pode transferir seu pet para você mesmo!',
        failed_to_transfer_ownership_could_not_find_new_owner_id = 'Não foi possível encontrar o novo dono (ID incorreto)',
        failed_to_transfer_ownership_missing_current_owner = 'Não é possível transferir este pet, informações do dono atual ausentes!',

        not_enough_water_bottles = 'Você não está carregando garrafas de água suficientes, mínimo: %d',
        not_enough_water_in_your_bottle = 'Sua garrafa de água está vazia!',

        pet_died = '%s morreu!'
    },
    success = {
        pet_initialization_was_successful = 'Parabéns pelo seu novo companheiro',
        pet_rename_was_successful = 'O nome do seu pet foi alterado para ',
        healing_was_successful = "Seu pet foi curado em: %s saúde máxima: %s",
        successful_revive = '%s seu pet reviveu',
        successful_ownership_transfer = 'A transferência foi bem-sucedida. Você pode agora entregar este pet ao novo dono',
        successful_drinking = 'A bebida foi bem-sucedida, espere um pouco para fazer efeito',
        successful_grooming = 'A tosa foi bem-sucedida',
    },
    info = {
        use_3th_eye = 'Use seu 3º olho no seu pet',
        full_life_pet = 'Seu pet está com a saúde cheia',
        still_on_cooldown = "Ainda em cooldown, restando: %s seg",
        level_up = '%s ganhou um novo nível %d'
    },
    menu = {
        general_menu_items = {
            btn_leave = 'Sair',
            btn_back = 'Voltar',
            success = 'Sucesso',
            confirm = 'Confirmar'
        },

        main_menu = {
            header = 'Nome: %s',
            sub_header = 'pet atual sob seu controle',
            btn_actions = 'Ações',
            btn_switchcontrol = 'Trocar Controle',
            switchcontrol_header = 'Trocar Pet Sob Seu Controle',
            switchcontrol_sub_header = 'clique no pet que você quer controlar',
        },

        action_menu = {
            header = 'Nome: %s',
            sub_header = 'pet atual sob seu controle',
            follow = 'Seguir Dono',
            hunt = 'Caçar',
            hunt_and_grab = 'Caçar e Pegar',
            go_there = 'Ir até lá',
            wait = 'Esperar aqui',
            get_in_car = 'Entrar no carro',
            beg = 'Fazer alguns truques',
            paw = 'Dar a pata',
            play_dead = 'Fingir de morto',
            tricks = 'Truques',
            error = {
                pet_unable_to_hunt = "Seu pet não pode caçar",
                not_meet_min_requirement_to_hunt = 'Seu pet precisa subir de nível para caçar. (nível mínimo: %s)',
                already_hunting_something = 'Já está caçando algo!',
                pet_unable_to_do_that = 'Não pode seguir seu comando',

                -- entrar no carro
                need_to_be_inside_car = 'Você precisa estar dentro de um carro',
                to_far = 'Muito longe',
                no_empty_seat = 'Nenhum assento vazio encontrado!'
            },
            success = {


            },
            info = {

            }
        },

        tricks = {
            header = 'Nome: %s',
            sub_header = 'pet atual sob seu controle',

        },

        switchControl_menu = {
            header = 'Nome: %s',
            sub_header = 'pet atual sob seu controle',

        },

        customization_menu = {
            header = 'Menu de Personalização',
            sub_header = '',

            btn_rename = 'Renomear',
            btn_txt_btn_rename = 'nome atual: ',

            btn_select_variation = 'Selecionar variação',
            btn_txt_select_variation = 'cor atual: ',


            rename = {
                inputs = {
                    header = 'Digite o novo nome'
                }
            }
        },

        rename_menu = {
            header = 'Nome atual',
            btn_rename = 'Renomear',
        },

        variation_menu = {
            header = 'Cor atual',
            btn_select_variation = 'Selecionar variação',
            btn_txt_select_variation = 'escolha a cor do seu pet',

            selection_menu = {
                header = 'Lista de variações',
                btn_variation_items = 'Variação: ',
                btn_desc = 'selecionar para fazer efeito',
            }

        },
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
