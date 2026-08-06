// Sample.java — exercises Moped's Java tokenizer.
package sample;

import java.util.ArrayList;
import java.util.List;

public class Library {
	private final List<String> titles = new ArrayList<>();
	private int checkoutCount = 0;

	/* Literal forms that trip tokenizers: escaped quotes, char literals including the
	   quote characters themselves, and numbers in every base. */
	private static final String QUOTED = "she said \"hello\" and left";
	private static final String BACKSLASH = "ends with a backslash \\";
	private static final char QUOTE_CHAR = '"';
	private static final char APOSTROPHE = '\'';
	private static final int[] BASES = {0xFF, 0b1010_1010, 0755, 1_000_000};
	private static final double SCIENTIFIC = 6.022e23;

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
