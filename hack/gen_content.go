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

type entry struct {
	org  string
	repo string
	src  string
	dest string
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

	var entries []entry
	for _, source := range info.Sources {
		repoName, _ := GetStringInBetweenTwoString(source.Repo, "https://github.com/kubernetes/", ".git")
		orgName := "kubernetes"
		for _, file := range source.Files {
			entries = append(entries, entry{orgName, repoName, file.Src, file.Dest})
		}
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
			Copy(copyFrom, copyTo, entries)
		}
	}

}

func Copy(src, dst string, entries []entry) error {
	input, err := ioutil.ReadFile(src)
	if err != nil {
		fmt.Println(err)
		return err
	}

	mkdown, mp := GetAllLinks(string(input), src, entries)
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

func GetAllLinks(markdown string, src string, entries []entry) (string, map[string]string) {
	// Holds all the links and their corresponding values
	m := make(map[string]string)

	// Regex to extract link for [text](./something.md)
	re := regexp.MustCompile(`\[([^\]]*)\]\(([^)]*)\)`)
	// Regex to extract link for [text]: ./something.md
	re2 := regexp.MustCompile(`^\[.*\]:\s(\S+)$`)

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
					foundLink := matches[0][2]
					var replacementLink string
					if strings.HasPrefix(foundLink, "http") {
						replacementLink = foundLink
					} else {
						replacementLink = ExpandPath(foundLink, src)
					}
					replacementLink = GenLink(replacementLink, entries)
					markdown = strings.Replace(markdown, matches[0][2], "hugo-url", -1)
					m[matches[0][1]] = matches[0][2]
				}
			}
			if matches2 != nil {
				if !strings.HasPrefix(matches2[0][1], "#") {
					markdown = strings.Replace(markdown, matches2[0][1], "hugo-url", -1)
					m[matches2[0][1]] = matches2[0][1]
				}
			}
		}
	}
	//fmt.Println(markdown)
	return markdown, m
}

func GenLink(replacementLink string, entries []entry) string {
	// if it is a web link
	if strings.HasPrefix(replacementLink, "http") {
		// if it belongs to one of the k8s urls check if it's present in the hugo site and replace
		// TODO: add more checks here  for now let's just work with "http://github.com/kubernetes"

		if strings.Contains(replacementLink, "http://github.com/kubernetes") {
			for _, entry := range entries {
				// TODO: remove blob tree master from the replacementLink else Contains won't work
				if strings.Contains(replacementLink, entry.src) {
					return entry.dest
				}
			}
		}
	} else {
		// if its not an external url check if present on hugo side if yes then replace with that else generate an external url
		for _, entry := range entries {
			if replacementLink == entry.src {
				return entry.dest
			}
		}
		// add logic for generating external link now

	}
	return replacementLink
}

func ExpandPath(foundLink string, src string) string {
	// if ./a.md or /a.md or a.md then it's in same dir as src
	if filepath.Dir(foundLink) == "." || filepath.Dir(foundLink) == "/" {
		return filepath.Dir(src) + filepath.Base(foundLink)
	}

	// if foundLink was ../../abc.md and src was /_temp/community/something/contributors/guide/README.md

	src = filepath.Dir(src)
	fileName := filepath.Base(foundLink)
	foundLink = filepath.Dir(foundLink)

	// foundLink is now ../.. src is now  /_temp/community/something/contributors/guide and fileName is abc.md

	linkSliceLen := len(strings.SplitAfter(foundLink, "/"))
	srcSlice := strings.SplitAfter(src, "/")

	// linkSliceLen is now 2 srcSlice is [_temp,community,something,contributors,guide]

	// we want to get the last 2 elements of srcSlice now
	srcSlice = srcSlice[len(srcSlice)-linkSliceLen:]

	// now srcSlice is [contributors, guide]

	// return contributors/guide/abc.md
	return strings.Join(srcSlice, "/") + fileName
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
