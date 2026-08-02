// Sample.java — exercises Moped's Java tokenizer.
package sample;

import java.util.ArrayList;
import java.util.List;

public class Library {
	private final List<String> titles = new ArrayList<>();
	private int checkoutCount = 0;

	public void addBook(String title) {
		titles.add(title);
	}

	public boolean checkout(String title) {
		if (titles.remove(title)) {
			checkoutCount++;
			return true;
		}
		return false;
	}

	public static void main(String[] args) {
		Library library = new Library();
		library.addBook("Effective Java");
		library.addBook("Clean Code");

		boolean success = library.checkout("Clean Code");
		System.out.println("Checked out: " + success);
		System.out.printf("Remaining titles: %d%n", library.titles.size());
	}
}
