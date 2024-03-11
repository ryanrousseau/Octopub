CREATE TABLE `audit` (
  `id` int NOT NULL AUTO_INCREMENT,
  `dataPartition` varchar(255) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `object` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `encryptedSubject` boolean NOT NULL,
  `encryptedObject` boolean NOT NULL,
  `time` timestamp NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

