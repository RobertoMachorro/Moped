/* This block comment is deliberately never closed.
 * Everything below should be tokenized as a comment, and the editor
 * must not stall while re-highlighting on each keystroke.

#include <stdio.h>

int main(void) {
	printf("This line is inside the open comment.\n");
	return 0;
}
