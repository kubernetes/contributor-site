package main

import (
	"fmt"
	"testing"
)

func Test_Expand_Path(t *testing.T) {
	fmt.Println(ExpandPath("election.md", "_tmp/community/committee-code-of-conduct/incident-process.md"))
	t.Fail()
}

func Test_Gen_Link(t *testing.T) {
	entries := make([]entry, 2)
	entries = append(entries, entry{org: "kubernetes", repo: "community", src: "/committee-code-of-conduct/incident-process.md", dest: "/community/code-of-conduct-incident-process.md"})
	fmt.Println("this", GenLink("/election.md", entries, "./_tmp/community/committee-code-of-conduct/incident-process.md"))
	t.Fail()
}
