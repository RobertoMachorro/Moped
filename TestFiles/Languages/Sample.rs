// Sample.rs — exercises Moped's Rust tokenizer.
use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Product {
	name: String,
	price_cents: u32,
}

fn total_value(inventory: &HashMap<String, Product>) -> u32 {
	inventory.values().map(|p| p.price_cents).sum()
}

/* A block comment /* nested inside another */ still closes here. */
fn separators() -> (char, char, &'static str) {
	let quote = '"'; // a char literal holding a double quote must not open a string
	let newline = '\n';
	let raw = r#"a raw string with "quotes" and a \backslash"#;
	(quote, newline, raw)
}

fn main() {
	let mut inventory: HashMap<String, Product> = HashMap::new();

	inventory.insert(
		"widget".to_string(),
		Product { name: "Widget".to_string(), price_cents: 1999 },
	);
	inventory.insert(
		"gadget".to_string(),
		Product { name: "Gadget".to_string(), price_cents: 4999 },
	);

	match inventory.get("widget") {
		Some(p) => println!("Found: {} at {} cents", p.name, p.price_cents),
		None => println!("Not found"),
	}

	println!("Total inventory value: {} cents", total_value(&inventory));
}
