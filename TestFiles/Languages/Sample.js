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
