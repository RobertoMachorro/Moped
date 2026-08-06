// Sample.js — exercises Moped's JavaScript tokenizer.
class EventBus {
	#listeners = new Map();

	on(event, callback) {
		if (!this.#listeners.has(event)) {
			this.#listeners.set(event, []);
		}
		this.#listeners.get(event).push(callback);
	}

	emit(event, ...args) {
		const handlers = this.#listeners.get(event) ?? [];
		handlers.forEach((cb) => cb(...args));
	}
}

const bus = new EventBus();

bus.on("greet", (name) => {
	console.log(`Hello, ${name}!`);
});

const users = ["Ada", "Grace"];
users.forEach((user) => bus.emit("greet", user));

const isReady = true;
export default isReady ? EventBus : null;

// Literal forms that trip tokenizers.
const quoted = "she said \"hello\" and left";
const single = 'it\'s escaped';
const division = users.length / 2 / 1;
const pattern = /"[^"]*"/g;
const bases = [0xff, 0b1010_1010, 0o755, 1_000_000, 9007199254740991n];
const scientific = 6.022e23;
