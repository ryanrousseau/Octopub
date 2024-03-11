CREATE TABLE `product` (
  `id` int NOT NULL AUTO_INCREMENT,
  `dataPartition` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `product`
(`dataPartition`,
`name`)
VALUES
('main', 'The 10 Pillars of Pragmatic Kubernetes Deployments'
);

CREATE TABLE `REVINFO` (
  `REV` int NOT NULL AUTO_INCREMENT,
  `REVTSTMP` bigint DEFAULT NULL,
  PRIMARY KEY (`REV`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `product_AUD` (
  `REV` int NOT NULL,
  `REVTYPE` tinyint DEFAULT NULL,
  `id` int NOT NULL,
  `dataPartition` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`REV`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

