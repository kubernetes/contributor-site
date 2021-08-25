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
		// TODO: add logic to handle more orgs -> DONE
		orgName := strings.SplitAfter(source.Repo, "/")[3]
		orgName = strings.ReplaceAll(orgName, "/", "")
		repoName := strings.SplitAfter(source.Repo, "/")[4]
		repoName = strings.ReplaceAll(repoName, ".git", "")
		// repoName, _ := GetStringInBetweenTwoString(source.Repo, "https://github.com/kubernetes/", ".git")
		// orgName := "kubernetes"
		for _, file := range source.Files {
			entries = append(entries, entry{orgName, repoName, file.Src, file.Dest})
		}
	}

	fmt.Println("$$$")
	fmt.Println(entries)
	fmt.Println("$$$")

	err = os.Mkdir("./_tmp", 0755)
	if err != nil {
		log.Fatal(err)
	}

	// err = os.Mkdir("./content", 0755)
	// if err != nil {
	// 	log.Fatal(err)
	// }

	// not iterating through "entries" so that we don't have to do multiple git clones
	for _, source := range info.Sources {
		repo := source.Repo
		folderName := strings.SplitAfter(repo, "/")[4]
		folderName = strings.ReplaceAll(folderName, ".git", "")
		concatenatedPath := "./_tmp/" + folderName
		gitClone := exec.Command("git", "clone", repo, concatenatedPath)
		err := gitClone.Run()
		if err != nil {
			log.Fatal(err)
		}

		for _, file := range source.Files {
			copyFrom := concatenatedPath + file.Src
			copyTo := "./content" + file.Dest
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

	mkdown := GetAllLinks(string(input), src, entries)

	dir, _ := filepath.Split(dst)
	// only create folders if they do not already exist
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		err = os.MkdirAll(dir, os.ModePerm)
		if err != nil {
			log.Fatal(err)
		}
	} else {
		fmt.Println("File Exists")
	}
	// err = os.MkdirAll(dir, os.ModePerm)
	// if err != nil {
	// 	log.Fatal(err)
	// }
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

// src is something like "./_tmp/community/contributors/guide/README.md"
func GetAllLinks(markdown string, src string, entries []entry) string {

	// Regex to extract link for [text](./something.md)
	// TODO: change this regex to return only the () and not both [] and ()
	re := regexp.MustCompile(`\[([^\]]*)\]\(([^)]*)\)`)
	// Regex to extract link for [text]: ./something.md
	re2 := regexp.MustCompile(`^\[.*\]:\s(\S+)$`)

	scanner := bufio.NewScanner(strings.NewReader(markdown))
	stop := false
	// Scans line by line
	for scanner.Scan() {
		// TODO: improve logic to stop only when same number of "`" are found
		if strings.HasPrefix(scanner.Text(), "```") {
			stop = !stop
		}

		if !stop {
			matches := re.FindAllStringSubmatch(scanner.Text(), -1)
			matches2 := re2.FindAllStringSubmatch(scanner.Text(), -1)

			if matches != nil {
				// for ignoring internal links
				if !strings.HasPrefix(matches[0][2], "#") {
					foundLink := matches[0][2]
					var replacementLink string
					if strings.HasPrefix(foundLink, "http") {
						replacementLink = foundLink
					} else {
						replacementLink = ExpandPath(foundLink, src)
					}
					fmt.Println("EXPANDED PATH", replacementLink)
					replacementLink = GenLink(replacementLink, entries, src)
					if foundLink != replacementLink {
						if !strings.HasPrefix(replacementLink, "http") {
							// TODO: remove md here and keep # in mind -> done
							replacementLink = strings.ReplaceAll(replacementLink, ".md", "")
							// TODO: if it's _index or index then remove the last part -> done
							replacementLink = strings.ReplaceAll(replacementLink, "_index", "")
							replacementLink = strings.ReplaceAll(replacementLink, "index", "")
						}
						fmt.Println("Replacing", foundLink, "with", replacementLink, "in", src)
						markdown = strings.Replace(markdown, matches[0][2], replacementLink, -1)
					}
				}
			}
			if matches2 != nil {
				if !strings.HasPrefix(matches2[0][1], "#") {
					markdown = strings.Replace(markdown, matches2[0][1], "hugo-url", -1)
				}
			}
		}
	}
	return markdown
}

func GenLink(replacementLink string, entries []entry, src string) string {
	// if it is a web link
	if strings.HasPrefix(replacementLink, "http") {
		// if it belongs to one of the k8s urls, replace if it will be present on the hugo site
		// TODO: add more checks here for now let's just work with "http://github.com/kubernetes"
		// for example replacementLink = https://github.com/kubernetes/community/blob/master/mentoring/programs/meet-our-contributors.md
		if strings.Contains(replacementLink, "github.com/kubernetes") || strings.Contains(replacementLink, "github.com/kubernetes-sigs") || strings.Contains(replacementLink, "github.com/kubernetes-csi") || strings.Contains(replacementLink, "github.com/kubernetes-client") || strings.Contains(replacementLink, "git.k8s.io") || strings.Contains(replacementLink, "sigs.k8s.io") {
			for _, entry := range entries {
				// one entry would be "/mentoring/programs/meet-our-contributors.md"
				// ?? TODO: remove blob tree master from the replacementLink else Contains won't work
				if strings.Contains(replacementLink, entry.src) {
					// return "/events/meet-our-contributors.md"
					return entry.dest
				}
			}
		}

		// if it's not one of the k8s urls just let it be

	} else {
		// if its not an external url check if it's present on hugo site

		// if yes then replace with that
		// for example replacement link "/contributors/guide/abc.md"
		for _, entry := range entries {
			if replacementLink == entry.src {
				return entry.dest
			}
		}
		// else generate an external url
		// for example replacement link "/mentoring/programs/shadow-roles.md"
		// src is something like "./_tmp/community/contributors/guide/README.md"
		fmt.Println("IT WENT HERE")
		fmt.Println("src", src)
		fmt.Println("replacementLink", replacementLink)

		// if replacementLink == "/contributors/devel/sig-architecture/api-conventions.md" {
		repo := strings.SplitAfter(src, "/")[2]
		repo = strings.ReplaceAll(repo, "/", "")
		// fmt.Println("repo", repo)
		for _, entry := range entries {
			// fmt.Println("entry.repo", entry.repo)
			// fmt.Println("repo", repo)
			if entry.repo == repo {
				// TODO: add blob/master also -> done
				fmt.Println("entry.dest", entry.dest)
				fmt.Println("repLink", replacementLink)
				fmt.Println("src", src)
				if strings.Contains(src, entry.src) {
					stuff := strings.Split(entry.src, "/")
					fmt.Println(stuff)
					if len(stuff) == 1 {
						return "https://github.com/" + entry.org + "/" + entry.repo + "/blob/master" + replacementLink
					} else {
						extra := "/"
						for k, v := range stuff {
							if k == (len(stuff) - 1) {
								continue
							}
							extra += v
						}

						return "https://github.com/" + entry.org + "/" + entry.repo + "/blob/master" + extra + replacementLink
					}
				}
			}
		}
		// fmt.Println("OVER $$$$$")
		// }

	}
	return replacementLink
}

// foundLink is something like ../../abc.md
// src is something like "./_tmp/community/contributors/guide/README.md"
// expandPath will return "/contributors/guide/abc.md"
func ExpandPath(foundLink string, src string) string {
	// if ./a.md or /a.md or a.md then it's in same dir as src
	if filepath.Dir(foundLink) == "." || filepath.Dir(foundLink) == "/" {
		// fullFilePath is "./_tmp/community/contributors/guide" + "/" +"abc.md"
		fullFilePath := filepath.Dir(src) + "/" + filepath.Base(foundLink)
		// we want to return "/" + "contributors/guide/abc.md"
		return "/" + strings.Join(strings.Split(fullFilePath, "/")[3:], "/")
	}

	// for cases where
	// foundLink is /contributors/devel/sig-architecture/api_changes.md
	// src is ./_tmp/community/contributors/guide/coding-conventions.md
	if !strings.Contains(foundLink, "..") {
		return foundLink
	}

	// if foundLink was ../../abc.md and src was ./_tmp/community/contributors/guide/README.md

	src = filepath.Dir(src)
	fileName := filepath.Base(foundLink)
	foundLink = filepath.Dir(foundLink)

	// src is now "./_tmp/community/contributors/guide"
	// fileName is now abc.md
	// foundLink is now ../..

	linkSliceLen := len(strings.SplitAfter(foundLink, "/"))
	srcSlice := strings.SplitAfter(src, "/")

	// linkSliceLen is now 2
	// srcSlice is now [., _tmp, community, contributors, guide]

	// we want to get the last 2 elements of srcSlice now
	srcSlice = srcSlice[len(srcSlice)-linkSliceLen:]

	// srcSlice is now [contributors, guide]

	// return "/" + "contributors/guide" + "/" + abc.md" = /contributors/guide/abc.md
	return "/" + strings.Join(srcSlice, "/") + "/" + fileName
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
