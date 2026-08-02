-- Sample.sql — exercises Moped's SQL tokenizer.
CREATE TABLE customers (
	id INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	email TEXT UNIQUE,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (id, name, email) VALUES
	(1, 'Ada Lovelace', 'ada@example.com'),
	(2, 'Grace Hopper', 'grace@example.com');

SELECT c.name, COUNT(o.id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.id
WHERE c.created_at >= '2024-01-01'
GROUP BY c.name
HAVING COUNT(o.id) > 0
ORDER BY order_count DESC;

/* Clean up test data when done. */
DELETE FROM customers WHERE email IS NULL;
