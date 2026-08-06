<?php
// Sample.php — exercises Moped's PHP tokenizer.

declare(strict_types=1);

class Cart
{
    /** @var array<string, float> */
    private array $items = [];

    public function addItem(string $name, float $price): void
    {
        $this->items[$name] = $price;
    }

    public function total(): float
    {
        return array_sum($this->items);
    }
}

$cart = new Cart();
$cart->addItem("Coffee", 4.50);
$cart->addItem("Croissant", 3.25);

// A heredoc closed the canonical way, with the terminator part of the statement.
$receipt = <<<SQL
    SELECT name, price FROM items WHERE cart = 'today'
SQL;

echo $receipt;

printf("Total: $%.2f\n", $cart->total());

if ($cart->total() > 5.0) {
    echo "That's a proper breakfast.\n";
}
