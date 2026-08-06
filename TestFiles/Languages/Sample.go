// Sample.go — exercises Moped's Go tokenizer.
package main

import (
	"fmt"
	"strings"
)

type Stack struct {
	items []string
}

func (s *Stack) Push(item string) {
	s.items = append(s.items, item)
}

func (s *Stack) Pop() (string, bool) {
	if len(s.items) == 0 {
		return "", false
	}
	last := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return last, true
}

func main() {
	stack := &Stack{}
	stack.Push("first")
	stack.Push("second")
	stack.Push("third")

	var popped []string
	for {
		item, ok := stack.Pop()
		if !ok {
			break
		}
		popped = append(popped, item)
	}

	fmt.Println("Popped order:", strings.Join(popped, ", "))
}

// Literal forms that trip tokenizers.
var quoted = "she said \"hello\" and left"
var rawLiteral = `a raw string where \n is literal and "quotes" need no escape`
var runes = []rune{'a', '\n', '\''}
var bases = []int{0xFF, 0b1010_1010, 0o755, 1_000_000}
var scientific = 6.022e23
