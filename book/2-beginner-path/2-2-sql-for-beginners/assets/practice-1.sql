CREATE TABLE `customers` (
  `customer_id` int PRIMARY KEY,
  `name` varchar(50) NOT NULL,
  `surname` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `shipping_country` varchar(50) NOT NULL,
  `shipping_address` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL
);

CREATE TABLE `orders` (
  `order_id` int PRIMARY KEY,
  `order_date` datetime NOT NULL,
  `amount_paid` float(10, 2) NOT NULL,
  `customer_id` int NOT NULL
);

CREATE TABLE `shippings` (
  `order_id` int NOT NULL,
  `customer_id` int NOT NULL,
  `shipping_date` datetime,
  `status` ENUM ('new', 'packed', 'shipping', 'delivered') NOT NULL
);

CREATE TABLE `products` (
  `product_id` int PRIMARY KEY,
  `name` varchar(50) NOT NULL,
  `description` varchar(255)
);

CREATE TABLE `order_cart` (
  `product_id` int NOT NULL,
  `order_id` int NOT NULL,
  `price` float(10, 2) NOT NULL,
  `customer_id` int NOT NULL
);

ALTER TABLE `orders` ADD FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`);

ALTER TABLE `shippings` ADD FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`);

ALTER TABLE `shippings` ADD FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`);

ALTER TABLE `order_cart` ADD FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`);

ALTER TABLE `order_cart` ADD FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`);

ALTER TABLE `order_cart` ADD FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`);
