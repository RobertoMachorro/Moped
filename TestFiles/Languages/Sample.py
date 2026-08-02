# Sample.py — exercises Moped's Python tokenizer.
from dataclasses import dataclass, field


@dataclass
class Recipe:
    name: str
    ingredients: list[str] = field(default_factory=list)
    servings: int = 4

    def scale(self, factor: float) -> "Recipe":
        return Recipe(
            name=self.name,
            ingredients=self.ingredients,
            servings=round(self.servings * factor),
        )


def total_servings(recipes: list[Recipe]) -> int:
    return sum(r.servings for r in recipes)


if __name__ == "__main__":
    soup = Recipe("Tomato Soup", ["tomatoes", "onion", "basil"], servings=4)
    scaled = soup.scale(2.5)

    print(f"{scaled.name} now serves {scaled.servings} people")
    print("Total servings:", total_servings([soup, scaled]))
