package main

import (
	"log"
	"os"
	"os/exec"
	"strconv"
)

func main() {
	// TODO: replace this with reading from env vars
	repos := []string{"https://github.com/kubernetes/community.git", "https://github.com/kubernetes/sig-release.git"}

	err := os.Mkdir("./_tmp", 0755)
	if err != nil {
		log.Fatal(err)
	}

	for i, r := range repos {
		// TODO: concatenate repo name instead
		concatenatedPath := "./_tmp/" + strconv.Itoa(i)
		gitClone := exec.Command("git", "clone", r, concatenatedPath)
		err := gitClone.Run()
		if err != nil {
			log.Fatal(err)
		}
	}
}
