package main

import (
	"bufio"
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
		// TODO: replace hard coded "community" with some variable
		concatenatedPath := "./_tmp/" + "community"
		gitClone := exec.Command("git", "clone", repo, concatenatedPath)
		err := gitClone.Run()
		if err != nil {
			log.Fatal(err)
		}

		for _, file := range source.Files {
			copyFrom := concatenatedPath + file.Src
			copyTo := "./_out" + file.Dest
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

	fmt.Println(GetAllLinks(string(input)))

	dir, _ := filepath.Split(dst)
	err = os.MkdirAll(dir, os.ModePerm)
	if err != nil {
		log.Fatal(err)
	}
	_, err = os.Create(dst)
	if err != nil {
		log.Fatal(err)
	}
	err = ioutil.WriteFile(dst, input, 0644)
	if err != nil {
		fmt.Println("Error creating", dst)
		fmt.Println(err)
		return err
	}
	return nil
}

func GetAllLinks(markdown string) map[string]string {
	// Holds all the links and their corresponding values
	m := make(map[string]string)

	// Regex to extract link and text attached to link
	re := regexp.MustCompile(`\[([^\]]*)\]\(([^)]*)\)`)

	scanner := bufio.NewScanner(strings.NewReader(markdown))
	stop := false
	// Scans line by line
	for scanner.Scan() {
		if strings.HasPrefix(scanner.Text(), "```") == true {
			stop = !stop
		}

		if stop == false {
			// Make regex
			matches := re.FindAllStringSubmatch(scanner.Text(), -1)

			// Only apply regex if there are links and the link does not start with #
			if matches != nil {
				if strings.HasPrefix(matches[0][2], "#") == false {
					// fmt.Println(matches[0][2])
					m[matches[0][1]] = matches[0][2]
				}
			}
		}
	}
	return m
}
