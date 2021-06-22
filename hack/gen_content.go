package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"

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
