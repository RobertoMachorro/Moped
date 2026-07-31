//
//  LineState.swift
//
//  MopedEditor - The homegrown text editor core and syntax highlighter used by Moped.
//  Copyright © 2019-2026 Roberto Machorro. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

/// The lexical state a line hands to the next one. This is what makes line-by-line
/// tokenizing incremental: after an edit, re-tokenizing can stop as soon as a line's
/// carry-out state matches the cached one.
public enum LineState: Equatable, Sendable {
	case none
	/// Inside a block comment. `ruleIndex` selects the language's block-comment rule,
	/// `depth` is only ever > 1 for languages with nesting comments (Swift, Rust).
	case blockComment(ruleIndex: Int, depth: Int)
	/// Inside a multiline string; `ruleIndex` selects the language's string rule.
	case string(ruleIndex: Int)
	/// Inside a heredoc body; ends on the line whose trimmed content equals `terminator`.
	case heredoc(terminator: String)
	/// Markdown: inside a fenced code block opened by `fence` ("```" or "~~~").
	case fencedCode(fence: String)
	/// HTML: inside a `<!-- -->` comment.
	case htmlComment
	/// HTML: inside a tag whose `>` hasn't been reached yet.
	case htmlTag
	/// XML: inside a `<![CDATA[ … ]]>` section.
	case cdata
	/// Outside the language's code region (PHP before `<?php` / after `?>`).
	case rawOutside
}
