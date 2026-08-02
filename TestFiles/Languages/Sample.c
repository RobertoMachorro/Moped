/* Sample.c — exercises Moped's C tokenizer. */
#include <stdio.h>
#include <string.h>

#define MAX_NAME 64

typedef struct {
	char name[MAX_NAME];
	int age;
} Person;

static int total_people = 0;

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
