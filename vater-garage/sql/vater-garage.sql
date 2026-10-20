-- Run this once only if your player_vehicles table does not already have these columns.
ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `garage` varchar(50) DEFAULT 'legion',
    ADD COLUMN IF NOT EXISTS `state` tinyint(1) DEFAULT 1,
    ADD COLUMN IF NOT EXISTS `fuel` int(11) DEFAULT 100,
    ADD COLUMN IF NOT EXISTS `engine` float DEFAULT 1000,
    ADD COLUMN IF NOT EXISTS `body` float DEFAULT 1000,
    ADD COLUMN IF NOT EXISTS `depotprice` int(11) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `favorite` tinyint(1) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `job` varchar(50) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `gang` varchar(50) DEFAULT NULL;
