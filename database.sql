INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('pizza_factuur', 'Pizza Factuur', 1, 0, 1);

INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES
('pizzabezorger', 'Pizzabezorger', 0);

INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
(1, 'pizzabezorger', 0, 'Bezorger', 'Bezorger', 500, '{}', '{}');