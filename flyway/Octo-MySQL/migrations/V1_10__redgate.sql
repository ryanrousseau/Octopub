-- Script generated by Redgate Compare v1.19.6.13291


-- deployment: Creating product_aud.audio_id...
ALTER TABLE product_aud ADD COLUMN audio_id int NULL;

-- add data


-- deployment: Creating product.new_product...
ALTER TABLE product ADD COLUMN new_product varchar(100) NULL;

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'VR Underwater Basket Weaving for Millennials', NULL, NULL, 'https://user-images.githubusercontent.com/160104/200216425-ea9c0f8c-d9ae-4a94-bee9-4a01c37d9a59.png', 'https://www.dropbox.com/s/8to2n5l6w70lzui/measuring-cd-and-devops.pdf?dl=1', 'Dive into crafting timeless baskets in serene virtual depths.'
);
