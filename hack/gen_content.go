package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"gopkg.in/yaml.v2"
)

type Info struct {
	Sources []struct {
		Repo  string `yaml:"repo"`
		Files []struct {
			Src  string `yaml:"src"`
			Dest string `yaml:"dest"`
		} `yaml:"files"`
	} `yaml:"sources"`
}

func main() {
	filename, _ := filepath.Abs("./info.yaml")
	yamlFile, err := ioutil.ReadFile(filename)

	if err != nil {
		log.Fatal(err)
	}

	var info Info
	err = yaml.Unmarshal(yamlFile, &info)
	if err != nil {
		log.Fatal(err)
	}

	err = os.Mkdir("./_tmp", 0755)
	if err != nil {
		log.Fatal(err)
	}

	err = os.Mkdir("./_out", 0755)
	if err != nil {
		log.Fatal(err)
	}

	for _, source := range info.Sources {
		repo := source.Repo
		folderName, _ := GetStringInBetweenTwoString(repo, "https://github.com/kubernetes/", ".git")
		concatenatedPath := "./_tmp/" + folderName
		gitClone := exec.Command("git", "clone", repo, concatenatedPath)
		err := gitClone.Run()
		if err != nil {
			log.Fatal(err)
		}

		for _, file := range source.Files {
			copyFrom := concatenatedPath + file.Src
			copyTo := "./_out/" + folderName + file.Dest
			Copy(copyFrom, copyTo)
		}
	}

}

func Copy(src, dst string) error {
	input, err := ioutil.ReadFile(src)
	if err != nil {
		fmt.Println(err)
		return err
	}

	mkdown, mp := GetAllLinks(string(input))
	PrettyPrint(mp)

	dir, _ := filepath.Split(dst)
	err = os.MkdirAll(dir, os.ModePerm)
	if err != nil {
		log.Fatal(err)
	}
	_, err = os.Create(dst)
	if err != nil {
		log.Fatal(err)
	}
	err = ioutil.WriteFile(dst, []byte(mkdown), 0644)
	if err != nil {
		fmt.Println("Error creating", dst)
		fmt.Println(err)
		return err
	}
	return nil
}

func GetAllLinks(markdown string) (string, map[string]string) {
	// Holds all the links and their corresponding values
	m := make(map[string]string)

	// Regex to extract link and text attached to link
	re := regexp.MustCompile(`\[([^\]]*)\]\(([^)]*)\)`)
	re2 := regexp.MustCompile(`\[([^\]]*)\]\:\ ([^ ]*)\w`)

	scanner := bufio.NewScanner(strings.NewReader(markdown))
	stop := false
	// Scans line by line
	for scanner.Scan() {
		if strings.HasPrefix(scanner.Text(), "```") {
			stop = !stop
		}

		if !stop {
			matches := re.FindAllStringSubmatch(scanner.Text(), -1)
			matches2 := re2.FindAllStringSubmatch(scanner.Text(), -1)

			if matches != nil {
				// for ignoring internal links
				if !strings.HasPrefix(matches[0][2], "#") {
					// TODO: add logic to build hugo link
					markdown = strings.Replace(markdown, matches[0][2], "hugo-url", -1)
					m[matches[0][1]] = matches[0][2]
				}
			}
			if matches2 != nil {
				if !strings.HasPrefix(matches2[0][2], "#") {
					markdown = strings.Replace(markdown, matches2[0][2], "hugo-url", -1)
					m[matches2[0][1]] = matches2[0][2]
				}
			}
		}
	}
	fmt.Println(markdown)
	return markdown, m
}

func GetStringInBetweenTwoString(str string, startS string, endS string) (result string, found bool) {
	s := strings.Index(str, startS)
	if s == -1 {
		return result, false
	}
	newS := str[s+len(startS):]
	e := strings.Index(newS, endS)
	if e == -1 {
		return result, false
	}
	result = newS[:e]
	return result, true
}

func PrettyPrint(v interface{}) (err error) {
	b, err := json.MarshalIndent(v, "", "  ")
	if err == nil {
		fmt.Println(string(b))
	}
	return
}
