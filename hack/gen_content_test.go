package main

import (
	"fmt"
	"testing"
)

func Test_Expand_Path_Same_Dir(t *testing.T) {
	fmt.Println(ExpandPath("election.md", "/contributors/guide/README.md"))
	t.Fail()
}

func Test_Expand_Path_No_Replace_Needed(t *testing.T) {
	fmt.Println(ExpandPath("/contributors/devel/sig-architecture/api_changes.md", "/contributors/guide/README.md"))
	t.Fail()
}

func Test_Expand_Path_Replace_Needed(t *testing.T) {
	fmt.Println(ExpandPath("../help/api_changes.md", "/contributors/guide/README.md"))
	t.Fail()
}

func Test_Gen_Link(t *testing.T) {
	entries := make([]entry, 2)
	entries = append(entries, entry{org: "kubernetes", repo: "community", src: "/committee-code-of-conduct/incident-process.md", dest: "/community/code-of-conduct-incident-process.md"})
	fmt.Println("this", GenLink("/election.md", entries, "./_tmp/community/committee-code-of-conduct/incident-process.md"))
	t.Fail()
}
