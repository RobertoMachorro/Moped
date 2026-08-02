// Sample.jsx — exercises Moped's JSX tokenizer.
import React, { useState } from "react";

const LABELS = ["draft", "review", "shipped"];

function Badge({ label }) {
	return <span className="badge">{label}</span>;
}

export default function Card({ title, items = [] }) {
	const [open, setOpen] = useState(false);

	// A comparison, not a tag: the `<` here must stay an operator.
	const overflow = items.length;
	for (let i = 0; i<overflow; i++) {
		console.log(`item ${i} of ${overflow}`);
	}

	return (
		<>
			<h2 onClick={() => setOpen(!open)}>{title}</h2>
			{open && (
				<ul className="card-items">
					{items.map((item) => (
						<li key={item.id}>
							<Badge label={LABELS[item.state]} /><em>{item.name}</em>
						</li>
					))}
				</ul>
			)}
			<hr />
		</>
	);
}
