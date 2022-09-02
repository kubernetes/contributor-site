# Release Opt-in Process Update

## Context and Motivations
Since the inception of the Kubernetes release team, we have used a spreadsheet to keep track of enhancements for the release. The project has scaled massively in the past few years, with almost a hundred enhancements collected for the 1.24 release. This process has become error-prone and time consuming. A lot of manual work is required from the release team and the SIG leads to populate KEPs data in the sheet. We have received continuous feedback from our contributors to streamline the process.

Starting in the 1.26 release, we are replacing the sheet with an automated Github project.

## How does the Github Board work?

The board is populated with a script gathering all KEP issues in the `kubernestes/enhancements` repo that have the tag `lead-oped-in`. The enhancements' stage and SIG information will also be automatically pulled from the KEP issue.


## What this means for the community

If you are not a SIG lead, not much will change beside the view of the enhancements collections and the change of platform. KEP authors will continue working with their respective SIG leads to opt-in to the release.

For SIG leads, opting in is simple. The KEP issue will be the single source of truth so ensure that all metadata are up to date. Simply apply the label`lead-opt-in` to be included in the release. Since the script runs periodically, kindly come back to check that the KEP is on the board and that there is an enhancements team member assigned to it.

We are excited to bring this highly requested feature into our release process and appreciate your patience. Please find us on Slack at #release-enhancemets if you have any feedback, questions or concern.
