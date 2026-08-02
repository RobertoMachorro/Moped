// Sample.tsx — exercises Moped's TSX tokenizer.
import React, { useMemo } from "react";

type State = "draft" | "review" | "shipped";

interface Item {
	id: number;
	name: string;
	state: State;
}

interface CardProps {
	title: string;
	items?: readonly Item[];
	onPick?: (item: Item) => void;
}

const Badge = ({ state }: { state: State }): JSX.Element => (
	<span className={`badge badge--${state}`}>{state}</span>
);

export function Card({ title, items = [], onPick }: CardProps) {
	const shipped = useMemo(() => items.filter((i) => i.state === "shipped"), [items]);

	// A comparison, not a tag: the `<` here must stay an operator.
	if (shipped.length<items.length) {
		console.warn(`${title}: ${items.length - shipped.length} still open`);
	}

	return (
		<>
			<h2>{title}</h2>
			<ul>
				{items.map((item) => (
					<li key={item.id} onClick={() => onPick?.(item)}>
						<Badge state={item.state} /><em>{item.name}</em>
					</li>
				))}
			</ul>
			<hr />
		</>
	);
}
