ALTER TABLE `product` 
ADD COLUMN `pdf` varchar(255) DEFAULT NULL,
ADD COLUMN `epub` varchar(255) DEFAULT NULL,
ADD COLUMN `image` varchar(255) DEFAULT NULL,
ADD COLUMN `web` varchar(255) DEFAULT NULL,
ADD COLUMN `description` longtext;

ALTER TABLE `product_AUD`
ADD COLUMN `pdf` varchar(255) DEFAULT NULL,
ADD COLUMN `epub` varchar(255) DEFAULT NULL,
ADD COLUMN `image` varchar(255) DEFAULT NULL,
ADD COLUMN `web` varchar(255) DEFAULT NULL,
ADD COLUMN `description` longtext;

UPDATE `product`
SET `pdf` = 'https://github.com/OctopusDeploy/TenPillarsK8s/releases/latest/download/tenpillarsk8s.pdf',
`epub` = 'https://github.com/OctopusDeploy/TenPillarsK8s/releases/latest/download/tenpillarsk8s.epub',
`image` = 'https://raw.githubusercontent.com/OctopusDeploy/TenPillarsK8s/main/KubernetesPDFcover.png',
`description` = 'Learn how to apply the 10 pillars of pragmatic deployments to your Kubernetes infrastructure with practical tips for configuring Octopus and managing your Kubernetes cluster.'
WHERE `id` = 8;

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'An introduction to DevOps', NULL, NULL, 'https://i.octopus.com/blog/2022-q2/introduction-to-devops/blogimage-introductiontodevops-2022.png', 'https://octopus.com/blog/introduction-to-devops', 'In this post, we take a surface-level look at the parts that make up DevOps. We explore the concepts, tools, unique roles, plus explain where Octopus fits in.'
);

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'An introduction to build servers and Continuous Integration', NULL, NULL, 'https://i.octopus.com/blog/2022-01/introduction-to-build-servers/blogimage-buildservers.png', 'https://octopus.com/blog/introduction-to-build-servers', 'Most development teams understand the importance of version control to coordinate code commits, and build servers to compile and package their software, but Continuous Integration (CI) is a big topic. Over the next few months, we’re going into detail about Continuous Integration and how two of the most popular build servers, Jenkins and GitHub Actions, can help with your CI processes.'
);

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'What is GitOps?', NULL, NULL, 'https://i.octopus.com/blog/2022-q2/what-is-gitops/blogimage-whatisgitops-2022.png', 'https://octopus.com/blog/what-is-gitops', ' in this post we look at: The history of GitOps, GitOps goals and ideals, The limitations of GitOps, The tools that support GitOps, The practical implications of adopting GitOps in your own organization'
);

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'The importance of Continuous Delivery', NULL, NULL, 'https://user-images.githubusercontent.com/160104/200215794-ee00c136-09e5-44a1-948f-3f2b07465be4.png', 'https://www.dropbox.com/s/ca80kc8hb64ttya/importance-of-cd.pdf?dl=1', 'In this white paper, you learn Continuous Delivery principles that will help you meet and exceed your goals.'
);

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'How to map your deployment pipeline', NULL, NULL, 'https://user-images.githubusercontent.com/160104/200216377-aa2f7d34-ebf0-414f-ab98-a96a27a691b7.png', 'https://www.dropbox.com/s/2ln1ij7fuqca6hh/map-deployment-pipeline.pdf?dl=1', 'Our white paper, How to map your deployment pipeline, addresses the challenges of adopting DevOps for any size team using any tech stack.'
);

INSERT INTO `product`
(`dataPartition`,
`name`,
`pdf`,
`epub`,
`image`,
`web`,
`description`)
VALUES
('main', 'Measuring Continuous Delivery and DevOps', NULL, NULL, 'https://user-images.githubusercontent.com/160104/200216425-ea9c0f8c-d9ae-4a94-bee9-4a01c37d9a59.png', 'https://www.dropbox.com/s/8to2n5l6w70lzui/measuring-cd-and-devops.pdf?dl=1', 'Our white paper, Measuring Continuous Delivery and DevOps, helps you measure the impact of software delivery improvements.'
);