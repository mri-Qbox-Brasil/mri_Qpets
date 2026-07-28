CREATE TABLE IF NOT EXISTS `player_pets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `gender` VARCHAR(10) DEFAULT 'male',
    `variation` VARCHAR(50) DEFAULT 'dark',
    `age` INT DEFAULT 0,
    `level` INT DEFAULT 1,
    `xp` INT DEFAULT 0,
    `health` INT DEFAULT 100,
    `hunger` INT DEFAULT 100,
    `thirst` INT DEFAULT 100, -- 100 is hydrated, decays to 0
    `happiness` INT DEFAULT 100, -- 100 is happy, decays to 0
    `active` INT DEFAULT 0, -- 0 = recolhido, 1 = spawnado
    `coords` VARCHAR(255) DEFAULT NULL,
    `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (`citizenid`)
);
