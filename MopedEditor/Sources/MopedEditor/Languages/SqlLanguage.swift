//
//  SqlLanguage.swift
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

extension LanguageDefinition {
	static let sqlLanguage = LanguageDefinition(
		id: "sql",
		keywords: [
			"add", "all", "alter", "analyze", "and", "as", "asc", "begin",
			"between", "by", "cascade", "case", "check", "column", "commit",
			"constraint", "create", "cross", "cursor", "database", "declare",
			"default", "delete", "desc", "distinct", "drop", "else", "end",
			"except", "exec", "exists", "explain", "foreign", "from", "full",
			"grant", "group", "having", "if", "index", "inner", "insert",
			"intersect", "into", "is", "join", "key", "left", "like", "limit",
			"natural", "not", "of", "offset", "on", "or", "order", "outer",
			"primary", "procedure", "recursive", "references", "revoke", "right",
			"rollback", "schema", "select", "set", "table", "then", "transaction",
			"trigger", "truncate", "union", "unique", "update", "using", "values",
			"view", "when", "where", "with"
		],
		returnKeywords: ["return", "returning"],
		typeKeywords: [
			"bigint", "binary", "bit", "blob", "boolean", "bytea", "char",
			"character", "clob", "date", "decimal", "double", "float", "int",
			"integer", "interval", "json", "jsonb", "numeric", "precision", "real",
			"serial", "smallint", "text", "time", "timestamp", "timestamptz",
			"uuid", "varchar", "varying"
		],
		builtins: ["null", "current_date", "current_time", "current_timestamp"],
		caseInsensitiveKeywords: true,
		lineCommentPrefixes: ["--"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(delimiter: "'", escape: nil),
			StringRule(delimiter: "\"", escape: nil)
		]
	)
}
