package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"sort"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

type Contribution struct {
	Author string `json:"author"`
	Points int    `json:"points"`
}

type Owners struct {
	Approvers []string `json:"approvers"`
	Reviewers []string `json:"reviewers"`
}

type RepoStats struct {
	Repo               string         `json:"repo"`
	LotteryFactor      int            `json:"lottery_factor"`
	TotalPoints        int            `json:"total_points"`
	Contributors       []Contribution `json:"contributors"`
	LastUpdated        string         `json:"last_updated"`
	TechStack          []string       `json:"tech_stack"`
	Owners             Owners         `json:"owners"`
	OnboardingURL      string         `json:"onboarding_url"`
	OwnersURL          string         `json:"owners_url"`
	IssuesURL          string         `json:"issues_url"`
	GoodFirstIssuesURL string         `json:"good_first_issues_url"`
}

type Subproject struct {
	Name  string   `json:"name"`
	Repos []string `json:"repos"`
}

type SIGStats struct {
	SIG         string       `json:"sig"`
	Subprojects []Subproject `json:"subprojects"`
	RepoData    []RepoStats  `json:"repo_data"`
}

type SigsYaml struct {
	Sigs []Sig `yaml:"sigs"`
}

type Sig struct {
	Dir         string           `yaml:"dir"`
	Name        string           `yaml:"name"`
	Subprojects []SubprojectYaml `yaml:"subprojects"`
}

type SubprojectYaml struct {
	Name   string   `yaml:"name"`
	Owners []string `yaml:"owners"`
}

func main() {
	since := time.Now().AddDate(0, -6, 0).Format("2006-01-02")
	sigName := "sig-contributor-experience"

	fmt.Println("Fetching sigs.yaml...")
	resp, err := http.Get("https://raw.githubusercontent.com/kubernetes/community/master/sigs.yaml")
	if err != nil {
		fmt.Printf("Failed to fetch sigs.yaml: %v\n", err)
		return
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Failed to read sigs.yaml: %v\n", err)
		return
	}

	var sigsData SigsYaml
	if err := yaml.Unmarshal(body, &sigsData); err != nil {
		fmt.Printf("Failed to parse sigs.yaml: %v\n", err)
		return
	}

	var subprojects []Subproject
	repoMap := make(map[string]bool)
	var repos []string

	for _, sig := range sigsData.Sigs {
		if sig.Dir == sigName {
			for _, sp := range sig.Subprojects {
				var spRepos []string
				for _, ownerUrl := range sp.Owners {
					parts := strings.Split(ownerUrl, "/")
					if len(parts) >= 6 && parts[2] == "raw.githubusercontent.com" {
						repo := parts[3] + "/" + parts[4]
						spRepos = append(spRepos, repo)
						if !repoMap[repo] {
							repoMap[repo] = true
							repos = append(repos, repo)
						}
					}
				}
				subprojects = append(subprojects, Subproject{
					Name:  sp.Name,
					Repos: spRepos,
				})
			}
		}
	}

	// Always add elekto if not already found (it's often under contribex but URL might differ)
	elektoRepo := "elekto-dev/elekto"
	if !repoMap[elektoRepo] {
		repoMap[elektoRepo] = true
		repos = append(repos, elektoRepo)
		subprojects = append(subprojects, Subproject{
			Name: "elections",
			Repos: []string{elektoRepo},
		})
	}

	var allRepoData []RepoStats
	for _, repo := range repos {
		fmt.Printf("Processing repository: %s\n", repo)
		stats := getRepoStats(repo, since)
		allRepoData = append(allRepoData, stats)
	}

	data := SIGStats{
		SIG:         sigName,
		Subprojects: subprojects,
		RepoData:    allRepoData,
	}

	file, _ := json.MarshalIndent(data, "", "  ")
	// Note: Action runs from hack dir, so path is ../static/data
	// Locally it might be static/data. We handle both.
	outputPath := "../static/data/lottery_factor.json"
	if _, err := os.Stat("static"); err == nil {
		outputPath = "static/data/lottery_factor.json"
	}
	
	_ = os.MkdirAll(strings.TrimSuffix(outputPath, "lottery_factor.json"), 0755)
	_ = os.WriteFile(outputPath, file, 0644)
	fmt.Printf("Successfully generated %s\n", outputPath)
}

func getBranch(repo string) string {
	out, err := exec.Command("gh", "repo", "view", repo, "--json", "defaultBranchRef", "-q", ".defaultBranchRef.name").Output()
	if err != nil {
		return "main"
	}
	return strings.TrimSpace(string(out))
}

func getOwnersMetadata(repo, branch string) Owners {
	fmt.Printf("  Fetching OWNERS for %s\n", repo)

	out, err := exec.Command("gh", "api", fmt.Sprintf("repos/%s/contents/OWNERS?ref=%s", repo, branch), "-q", ".content").Output()
	if err != nil {
		fmt.Printf("  No OWNERS file found for %s\n", repo)
		return Owners{}
	}

	s := strings.ReplaceAll(string(out), "\n", "")
	s = strings.ReplaceAll(s, "\r", "")
	contentBytes, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		return Owners{}
	}

	var data struct {
		Approvers []string `yaml:"approvers"`
		Reviewers []string `yaml:"reviewers"`
		Filters   map[string]struct {
			Approvers []string `yaml:"approvers"`
			Reviewers []string `yaml:"reviewers"`
		} `yaml:"filters"`
	}

	yaml.Unmarshal(contentBytes, &data)

	apprMap := make(map[string]bool)
	revMap := make(map[string]bool)

	for _, a := range data.Approvers {
		apprMap[a] = true
	}
	for _, r := range data.Reviewers {
		revMap[r] = true
	}

	for _, filter := range data.Filters {
		for _, a := range filter.Approvers {
			apprMap[a] = true
		}
		for _, r := range filter.Reviewers {
			revMap[r] = true
		}
	}

	var finalAppr, finalRev []string
	for a := range apprMap {
		if a != "" && !strings.HasPrefix(a, "sig-") && !strings.HasPrefix(a, "committee-") {
			finalAppr = append(finalAppr, a)
		}
	}
	for r := range revMap {
		if r != "" && !strings.HasPrefix(r, "sig-") && !strings.HasPrefix(r, "committee-") {
			finalRev = append(finalRev, r)
		}
	}

	sort.Strings(finalAppr)
	sort.Strings(finalRev)

	return Owners{
		Approvers: finalAppr,
		Reviewers: finalRev,
	}
}

func getTechStack(repo string) []string {
	fmt.Printf("  Fetching tech stack for %s\n", repo)
	
	stackMap := make(map[string]bool)

	// 1. Fetch Topics
	outTopics, _ := exec.Command("gh", "repo", "view", repo, "--json", "repositoryTopics", "-q", ".repositoryTopics[].name").Output()
	topics := strings.Split(strings.TrimSpace(string(outTopics)), "\n")
	for _, t := range topics {
		if t != "" && t != "kubernetes" && !strings.Contains(t, "sig-") && !strings.Contains(t, "k8s-") {
			stackMap[strings.Title(t)] = true
		}
	}

	// 2. Fetch Languages
	outLangs, _ := exec.Command("gh", "api", fmt.Sprintf("repos/%s/languages", repo)).Output()
	var langs map[string]int
	json.Unmarshal(outLangs, &langs)

	for l := range langs {
		name := l
		if l == "Dockerfile" { name = "Docker" }
		if l == "Shell" { name = "Bash" }
		if l == "Markdown" { name = "Documentation" }
		if l == "YAML" { name = "Infrastructure" }
		stackMap[name] = true
	}

	// 3. Framework & Tool Heuristics
	// Check for Hugo
	_, err := exec.Command("gh", "api", fmt.Sprintf("repos/%s/contents/hugo.yaml", repo)).Output()
	if err == nil { stackMap["Hugo"] = true }
	
	// Check for GitHub Actions
	_, err = exec.Command("gh", "api", fmt.Sprintf("repos/%s/contents/.github/workflows", repo)).Output()
	if err == nil { stackMap["GitHub Actions"] = true }

	// Check for Docsy in package.json
	outPkg, err := exec.Command("gh", "api", fmt.Sprintf("repos/%s/contents/package.json", repo), "-q", ".content").Output()
	if err == nil {
		s := strings.ReplaceAll(string(outPkg), "\n", "")
		content, _ := base64.StdEncoding.DecodeString(s)
		if strings.Contains(string(content), "docsy") {
			stackMap["Docsy"] = true
		}
	}

	// 4. Community-specific Fallbacks
	if strings.Contains(repo, "community") {
		stackMap["Community Management"] = true
		stackMap["Documentation"] = true
	}
	if strings.Contains(repo, "org") || strings.Contains(repo, "maintainers") {
		stackMap["Prow"] = true
		stackMap["Infrastructure"] = true
	}

	var result []string
	// Prioritize frameworks and key technologies
	priority := []string{"Hugo", "Docsy", "Docker", "Go", "TypeScript", "Python", "GitHub Actions", "Documentation", "Infrastructure"}
	for _, p := range priority {
		if stackMap[p] {
			result = append(result, p)
			delete(stackMap, p)
		}
	}

	var remaining []string
	for k := range stackMap { remaining = append(remaining, k) }
	sort.Strings(remaining)
	result = append(result, remaining...)

	if len(result) == 0 {
		return []string{"Documentation"}
	}
	if len(result) > 5 {
		return result[:5]
	}
	return result
}

func getRepoStats(repo, since string) RepoStats {
	counts := make(map[string]int)

	// Fetch PRs
	outPR, err := exec.Command("gh", "search", "prs", "--repo", repo, "--created", ">"+since, "--json", "author", "--limit", "500").Output()
	if err == nil {
		var prs []struct {
			Author struct {
				Login string `json:"login"`
			} `json:"author"`
		}
		json.Unmarshal(outPR, &prs)
		for _, pr := range prs {
			if pr.Author.Login != "" {
				counts[pr.Author.Login]++
			}
		}
	}

	// Fetch Issues
	outIssue, err := exec.Command("gh", "search", "issues", "--repo", repo, "--created", ">"+since, "--json", "author", "--limit", "500").Output()
	if err == nil {
		var issues []struct {
			Author struct {
				Login string `json:"login"`
			} `json:"author"`
		}
		json.Unmarshal(outIssue, &issues)
		for _, issue := range issues {
			if issue.Author.Login != "" {
				counts[issue.Author.Login]++
			}
		}
	}

	// Fetch Commits
	outCommits, err := exec.Command("gh", "api", fmt.Sprintf("repos/%s/commits?since=%sT00:00:00Z&per_page=100", repo, since)).Output()
	if err == nil {
		var commits []struct {
			Author struct {
				Login string `json:"login"`
			} `json:"author"`
		}
		json.Unmarshal(outCommits, &commits)
		for _, commit := range commits {
			if commit.Author.Login != "" {
				counts[commit.Author.Login]++
			}
		}
	}

	var contributors []Contribution
	total := 0
	for author, pts := range counts {
		if author == "" {
			continue
		}
		if strings.HasSuffix(author, "-bot") || strings.HasSuffix(author, "[bot]") || author == "k8s-ci-robot" || author == "k8s-triage-robot" || author == "k8s-infra-robot" {
			continue
		}
		contributors = append(contributors, Contribution{Author: author, Points: pts})
		total += pts
	}

	sort.Slice(contributors, func(i, j int) bool {
		return contributors[i].Points > contributors[j].Points
	})

	lf := 0
	runningSum := 0
	for _, c := range contributors {
		runningSum += c.Points
		lf++
		if total == 0 || runningSum > total/2 {
			break
		}
	}

	branch := getBranch(repo)
	techStack := getTechStack(repo)
	owners := getOwnersMetadata(repo, branch)

	onboardingUrl := fmt.Sprintf("https://github.com/%s/blob/%s/CONTRIBUTING.md", repo, branch)
	if strings.Contains(repo, "community") {
		onboardingUrl = "https://www.kubernetes.dev/docs/guide/"
	} else if repo == "kubernetes-sigs/maintainers" {
		onboardingUrl = fmt.Sprintf("https://github.com/%s", repo)
	}

	ownersUrl := fmt.Sprintf("https://github.com/%s/blob/%s/OWNERS", repo, branch)
	if repo == "elekto-dev/elekto" {
		ownersUrl = fmt.Sprintf("https://github.com/%s/graphs/contributors", repo)
	}

	return RepoStats{
		Repo:               repo,
		LotteryFactor:      lf,
		TotalPoints:        total,
		Contributors:       contributors,
		LastUpdated:        time.Now().Format(time.RFC3339),
		TechStack:          techStack,
		Owners:             owners,
		OnboardingURL:      onboardingUrl,
		OwnersURL:          ownersUrl,
		IssuesURL:          fmt.Sprintf("https://github.com/%s/issues", repo),
		GoodFirstIssuesURL: fmt.Sprintf("https://github.com/%s/issues?q=is%%3Aissue+is%%3Aopen+label%3A%%22good+first+issue%%22", repo),
	}
}
