package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/google/go-github/v60/github"
	"golang.org/x/oauth2"
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
	CreatedAt          string         `json:"created_at"`
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
	SIGs               []string       `json:"sigs"`
	Subprojects        []string       `json:"subprojects"` // Track subprojects that own this repo
}

type Subproject struct {
	Name  string   `json:"name"`
	Repos []string `json:"repos"`
}

type SIGData struct {
	Name        string       `json:"name"`
	Subprojects []Subproject `json:"subprojects"`
}

type SIGStats struct {
	SIGs     []SIGData   `json:"sigs"`
	RepoData []RepoStats `json:"repo_data"`
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

type Config struct {
	TargetSigs      []string `yaml:"target_sigs"`
	AdditionalRepos []struct {
		Repo       string `yaml:"repo"`
		Subproject string `yaml:"subproject"`
	} `yaml:"additional_repos"`
	Overrides map[string]RepoOverride `yaml:"overrides"`
}

type RepoOverride struct {
	OnboardingURL string `yaml:"onboarding_url"`
	OwnersURL     string `yaml:"owners_url"`
}

var client *github.Client
var ctx = context.Background()
var globalConfig Config

func loadConfig() error {
	data, err := os.ReadFile("dashboard-config.yaml")
	if err != nil {
		return err
	}
	return yaml.Unmarshal(data, &globalConfig)
}

func main() {
	if err := loadConfig(); err != nil {
		fmt.Printf("Failed to load config: %v\n", err)
		return
	}

	token := os.Getenv("GH_TOKEN")
	if token == "" {
		fmt.Println("GH_TOKEN not set. Using unauthenticated client (rate limits will be low).")
		client = github.NewClient(nil)
	} else {
		ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
		tc := oauth2.NewClient(ctx, ts)
		client = github.NewClient(tc)
	}

	since := time.Now().AddDate(0, -6, 0)

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

	var sigResults []SIGData
	repoStatsMap := make(map[string]*RepoStats)
	var repos []string

	targetSigsMap := make(map[string]bool)
	for _, s := range globalConfig.TargetSigs {
		targetSigsMap[s] = true
	}

	for _, sig := range sigsData.Sigs {
		if targetSigsMap[sig.Dir] {
			currentSIG := SIGData{Name: sig.Name}
			// De-duplication map for the current SIG to ensure a repo only appears once in the treemap hierarchy
			assignedInSIG := make(map[string]bool)

			for _, sp := range sig.Subprojects {
				var spRepos []string
				for _, ownerUrl := range sp.Owners {
					parts := strings.Split(ownerUrl, "/")
					if len(parts) >= 6 && parts[2] == "raw.githubusercontent.com" {
						repoName := parts[3] + "/" + parts[4]
						
						// Initialize metadata if repo not seen before
						if repoStatsMap[repoName] == nil {
							repoStatsMap[repoName] = &RepoStats{Repo: repoName}
							repos = append(repos, repoName)
						}

						// Metadata: Track all SIGs and Subprojects that own this repo
						repoStatsMap[repoName].SIGs = appendUnique(repoStatsMap[repoName].SIGs, sig.Name)
						repoStatsMap[repoName].Subprojects = appendUnique(repoStatsMap[repoName].Subprojects, sp.Name)

						// Visualization: Only add to the first subproject that claims it within this SIG
						if !assignedInSIG[repoName] {
							spRepos = append(spRepos, repoName)
							assignedInSIG[repoName] = true
						}
					}
				}
				if len(spRepos) > 0 {
					currentSIG.Subprojects = append(currentSIG.Subprojects, Subproject{
						Name:  sp.Name,
						Repos: spRepos,
					})
				}
			}
			sigResults = append(sigResults, currentSIG)
		}
	}

	// Add manual additions from config
	for _, ar := range globalConfig.AdditionalRepos {
		repoName := ar.Repo
		if repoStatsMap[repoName] == nil {
			repoStatsMap[repoName] = &RepoStats{Repo: repoName}
			repos = append(repos, repoName)
		}
		
		found := false
		for i, s := range sigResults {
			if strings.Contains(strings.ToLower(s.Name), "contributor experience") {
				subfound := false
				for j, sp := range s.Subprojects {
					if sp.Name == ar.Subproject {
						sigResults[i].Subprojects[j].Repos = appendUnique(sigResults[i].Subprojects[j].Repos, repoName)
						subfound = true; break
					}
				}
				if !subfound {
					sigResults[i].Subprojects = append(sigResults[i].Subprojects, Subproject{
						Name: ar.Subproject,
						Repos: []string{repoName},
					})
				}
				found = true; break
			}
		}
		if !found {
			sigResults = append(sigResults, SIGData{
				Name: "Additional Projects",
				Subprojects: []Subproject{{Name: ar.Subproject, Repos: []string{repoName}}},
			})
		}
	}

	var allRepoData []RepoStats
	for _, repoName := range repos {
		fmt.Printf("Processing repository: %s\n", repoName)
		stats := getRepoStats(repoName, since)
		// Merge discovered metadata
		stats.SIGs = repoStatsMap[repoName].SIGs
		stats.Subprojects = repoStatsMap[repoName].Subprojects
		allRepoData = append(allRepoData, stats)
	}

	sort.Slice(allRepoData, func(i, j int) bool {
		return allRepoData[i].CreatedAt < allRepoData[j].CreatedAt
	})

	data := SIGStats{
		SIGs:     sigResults,
		RepoData: allRepoData,
	}

	file, _ := json.MarshalIndent(data, "", "  ")
	outputPath := "../data/lottery_factor.json"
	if _, err := os.Stat("data"); err == nil {
		outputPath = "data/lottery_factor.json"
	}
	
	_ = os.MkdirAll(strings.TrimSuffix(outputPath, "lottery_factor.json"), 0755)
	_ = os.WriteFile(outputPath, file, 0644)
	fmt.Printf("Successfully generated %s\n", outputPath)
}

func appendUnique(slice []string, val string) []string {
	for _, item := range slice {
		if item == val { return slice }
	}
	return append(slice, val)
}

func parseRepo(repo string) (string, string) {
	parts := strings.Split(repo, "/")
	return parts[0], parts[1]
}

func getRepoStats(fullRepo string, since time.Time) RepoStats {
	owner, repo := parseRepo(fullRepo)
	
	r, _, err := client.Repositories.Get(ctx, owner, repo)
	if err != nil {
		return RepoStats{Repo: fullRepo}
	}

	branch := r.GetDefaultBranch()
	createdAt := r.GetCreatedAt().Format(time.RFC3339)

	counts := make(map[string]int)

	// Fetch PRs
	opts := &github.PullRequestListOptions{
		State: "all",
		ListOptions: github.ListOptions{PerPage: 100},
	}
	for {
		prs, resp, err := client.PullRequests.List(ctx, owner, repo, opts)
		if err != nil { break }
		finished := false
		for _, pr := range prs {
			if pr.GetCreatedAt().Before(since) {
				finished = true
				break
			}
			if pr.User != nil {
				counts[pr.User.GetLogin()]++
			}
		}
		if finished || resp.NextPage == 0 { break }
		opts.Page = resp.NextPage
	}

	// Fetch Issues
	issueOpts := &github.IssueListByRepoOptions{
		State: "all",
		Since: since,
		ListOptions: github.ListOptions{PerPage: 100},
	}
	for {
		issues, resp, err := client.Issues.ListByRepo(ctx, owner, repo, issueOpts)
		if err != nil { break }
		for _, issue := range issues {
			if issue.IsPullRequest() { continue }
			if issue.User != nil {
				counts[issue.User.GetLogin()]++
			}
		}
		if resp.NextPage == 0 { break }
		issueOpts.Page = resp.NextPage
	}

	// Fetch Commits
	commitOpts := &github.CommitsListOptions{
		Since: since,
		ListOptions: github.ListOptions{PerPage: 100},
	}
	for {
		commits, resp, err := client.Repositories.ListCommits(ctx, owner, repo, commitOpts)
		if err != nil { break }
		for _, commit := range commits {
			if commit.Author != nil {
				counts[commit.Author.GetLogin()]++
			}
		}
		if resp.NextPage == 0 { break }
		commitOpts.Page = resp.NextPage
	}

	var contributors []Contribution
	total := 0
	for author, pts := range counts {
		if author == "" || isBot(author) { continue }
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

	techStack := getTechStack(owner, repo, branch)
	owners := getOwnersMetadata(owner, repo, branch)

	onboardingUrl := fmt.Sprintf("https://github.com/%s/blob/%s/CONTRIBUTING.md", fullRepo, branch)
	ownersUrl := fmt.Sprintf("https://github.com/%s/blob/%s/OWNERS", fullRepo, branch)

	if override, ok := globalConfig.Overrides[fullRepo]; ok {
		if override.OnboardingURL != "" {
			onboardingUrl = override.OnboardingURL
		}
		if override.OwnersURL != "" {
			ownersUrl = override.OwnersURL
		}
	}

	return RepoStats{
		Repo:               fullRepo,
		CreatedAt:          createdAt,
		LotteryFactor:      lf,
		TotalPoints:        total,
		Contributors:       contributors,
		LastUpdated:        time.Now().Format(time.RFC3339),
		TechStack:          techStack,
		Owners:             owners,
		OnboardingURL:      onboardingUrl,
		OwnersURL:          ownersUrl,
		IssuesURL:          fmt.Sprintf("https://github.com/%s/issues", fullRepo),
		GoodFirstIssuesURL: fmt.Sprintf("https://github.com/%s/issues?q=is%%3Aissue+is%%3Aopen+label%%3A%%22good+first+issue%%22", fullRepo),
	}
}

func isBot(author string) bool {
	bots := map[string]bool{
		"k8s-ci-robot": true, "k8s-triage-robot": true, "k8s-infra-robot": true,
		"fejta-bot": true, "k8s-cherrypick-robot": true,
	}
	return bots[author] || strings.HasSuffix(author, "-bot") || strings.HasSuffix(author, "[bot]")
}

func getOwnersMetadata(owner, repo, branch string) Owners {
	fileContent, _, _, err := client.Repositories.GetContents(ctx, owner, repo, "OWNERS", &github.RepositoryContentGetOptions{Ref: branch})
	if err != nil {
		return Owners{}
	}

	content, _ := fileContent.GetContent()
	
	var data struct {
		Approvers []string `yaml:"approvers"`
		Reviewers []string `yaml:"reviewers"`
		Filters   map[string]struct {
			Approvers []string `yaml:"approvers"`
			Reviewers []string `yaml:"reviewers"`
		} `yaml:"filters"`
	}

	yaml.Unmarshal([]byte(content), &data)

	apprMap := make(map[string]bool)
	revMap := make(map[string]bool)

	for _, a := range data.Approvers { apprMap[a] = true }
	for _, r := range data.Reviewers { revMap[r] = true }

	for _, filter := range data.Filters {
		for _, a := range filter.Approvers { apprMap[a] = true }
		for _, r := range filter.Reviewers { revMap[r] = true }
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

	return Owners{Approvers: finalAppr, Reviewers: finalRev}
}

func getTechStack(owner, repo, branch string) []string {
	stackMap := make(map[string]bool)

	r, _, _ := client.Repositories.Get(ctx, owner, repo)
	for _, t := range r.Topics {
		if t != "" && t != "kubernetes" && !strings.Contains(t, "sig-") && !strings.Contains(t, "k8s-") {
			stackMap[strings.Title(t)] = true
		}
	}

	// 2. Languages (Ranked by size)
	langs, _, _ := client.Repositories.ListLanguages(ctx, owner, repo)
	type langItem struct {
		name string
		size int
	}
	var sortedLangs []langItem
	for l, s := range langs {
		name := l
		if l == "Dockerfile" { name = "Docker" }
		if l == "Shell" { name = "Bash" }
		sortedLangs = append(sortedLangs, langItem{name, s})
	}
	sort.Slice(sortedLangs, func(i, j int) bool {
		return sortedLangs[i].size > sortedLangs[j].size
	})

	// Add top 3 languages regardless of priority
	for i := 0; i < len(sortedLangs) && i < 3; i++ {
		stackMap[sortedLangs[i].name] = true
	}

	// 3. Archetype Detection (Dependency Analysis)
	goMod, _, _, err := client.Repositories.GetContents(ctx, owner, repo, "go.mod", &github.RepositoryContentGetOptions{Ref: branch})
	if err == nil {
		content, _ := goMod.GetContent()
		if strings.Contains(content, "sigs.k8s.io/controller-runtime") {
			stackMap["Operator"] = true
		} else if strings.Contains(content, "k8s.io/client-go") {
			stackMap["Controller"] = true
		}
		
		if strings.Contains(content, "github.com/spf13/cobra") {
			stackMap["CLI Tool"] = true
		}
		if strings.Contains(content, "github.com/prometheus/client_golang") {
			stackMap["Metrics"] = true
		}
		if strings.Contains(content, "github.com/onsi/ginkgo") {
			stackMap["E2E Tested"] = true
		}
		if strings.Contains(content, "k8s.io/code-generator") {
			stackMap["API Machinery"] = true
		}
	}

	_, _, _, err = client.Repositories.GetContents(ctx, owner, repo, "hugo.yaml", &github.RepositoryContentGetOptions{Ref: branch})
	if err == nil { stackMap["Hugo"] = true }
	
	pkgJson, _, _, err := client.Repositories.GetContents(ctx, owner, repo, "package.json", &github.RepositoryContentGetOptions{Ref: branch})
	if err == nil {
		content, _ := pkgJson.GetContent()
		if strings.Contains(content, "docsy") {
			stackMap["Docsy"] = true
		}
	}

	var result []string
	priority := []string{"Operator", "CLI Tool", "API Machinery", "Hugo", "Docsy", "Metrics", "E2E Tested", "Python", "Go", "TypeScript", "Docker"}
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

	if len(result) == 0 { return []string{"Documentation"} }
	if len(result) > 5 { return result[:5] }
	return result
}
