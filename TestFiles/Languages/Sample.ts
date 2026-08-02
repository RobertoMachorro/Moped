// Sample.ts — exercises Moped's TypeScript tokenizer.
interface User {
	id: number;
	name: string;
	email?: string;
}

type Role = "admin" | "editor" | "viewer";

class UserStore {
	private users: Map<number, User> = new Map();

	add(user: User): void {
		this.users.set(user.id, user);
	}

	findById(id: number): User | undefined {
		return this.users.get(id);
	}

	assignRole(id: number, role: Role): string {
		const user = this.findById(id);
		return user ? `${user.name} is now ${role}` : "User not found";
	}
}

const store = new UserStore();
store.add({ id: 1, name: "Ada Lovelace", email: "ada@example.com" });

const message: string = store.assignRole(1, "admin");
console.log(message);
