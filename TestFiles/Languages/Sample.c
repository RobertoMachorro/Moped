/* Sample.c — exercises Moped's C tokenizer. */
#include <stdio.h>
#include <string.h>

#define MAX_NAME 64

typedef struct {
	char name[MAX_NAME];
	int age;
} Person;

static int total_people = 0;

/* Literal forms that trip tokenizers: escaped quotes, char literals including the
   quote characters themselves, and numbers in every base. */
static const char *quoted = "she said \"hello\" and left";
static const char *backslash = "ends with a backslash \\";
static const char quote_char = '"';
static const char apostrophe = '\'';
static const char newline_char = '\n';
static const int bases[] = {0xFF, 0755, 1000000};
static const double scientific = 6.022e23;

void greet(const Person *p) {
	printf("Hello, %s! You are %d years old.\n", p->name, p->age);
}

int main(void) {
	Person people[2] = {
		{"Ada", 36},
		{"Grace", 85}
	};

	for (int i = 0; i < 2; i++) {
		greet(&people[i]);
		total_people++;
	}

	printf("Total people: %d\n", total_people);
	return 0;
}
