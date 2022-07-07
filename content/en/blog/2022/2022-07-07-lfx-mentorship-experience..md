---
layout: blog
title: "Experience of LFX Mentorship for CNCF: Kubernetes"
date: 2022-07-07
slug: experience-of-lfx-mentorship-for-cncf-kubernetes
---

 **Author:** Meha Bhalodiya

![LFX](https://miro.medium.com/max/1400/1*foy7v3BL7W99tf0AgTfalg.png)

It was a great and exciting feeling to start this journey! And here I am, at the end of it, graduated from the [LFX Mentorship program](https://mentorship.lfx.linuxfoundation.org/), writing this blog. It was wonderful, everything that I expected it to be, and even more so in the 3 months! I am writing this blog about my experience in this mentorship.

## LFX Mentorship? What’s that?

As the Linux Foundation calls it,

>“The Linux Foundation Mentorship Program is designed to help developers — many of whom are first-time open source contributors — with necessary skills and resources to learn, experiment, and contribute effectively to open source communities. By participating in a mentorship program, mentees have the opportunity to learn from experienced open source contributors as a segue to get internship and job opportunities upon graduation.”

*Note: You can apply for a maximum of 3 organizations at a time.*

Please have a look at the Mentorship guide to learn how to participate in LFX Mentorship programs: [lfx.linuxfoundation.org/mentorship/guide](https://lfx.linuxfoundation.org/tools/mentorship/guide)

## My acceptance into the program

Once the application process began, I drafted a cover letter, acknowledging some of the required questions included How did you find out about our mentorship program? Why are you interested in this program? What experience and knowledge/skills do you have that are applicable to this program? What do you hope to get out of this mentorship experience?

I submitted my application to 2 of the organizations i.e. **_Discovering Linux kernel subsystems used by OpenAPS (ELISA)_** and **_CNCF — Kubernetes SIG Network: Documentation assessment_**. Fortunately, I got acceptance from both of the organizations.

![Acceptance Mail from ELISA](https://miro.medium.com/max/1400/1*NfDYbjnxyJo6CwQhVsa7Nw.png)

![Acceptance Mail from CNCF](https://miro.medium.com/max/1230/1*3W_hB6OeU7szKaZOUzit4A.png)

In my position with both of the organizations, I interacted with [Shuah](https://www.linkedin.com/in/shuah-khan/) and received an email from her saying,

> Our records show you have been accepted the following CNCF Mentorship — CNCF — Kubernetes SIG Network: Documentation assessment.
>
> We don’t allow parallel participation and also once you graduate from LFX mentorship, you won’t be able to apply again. Our mentorships are one-time opportunities.

Also, got confirmation regarding my query from [Min](https://www.linkedin.com/in/min-yu-0b482a119/),

> LFX mentorships do not allow that. A mentee can’t work on two mentorship projects concurrently. If you are selected for two mentorship projects you will need to select one by withdrawing your application from the other.
>
> The Linux Foundation mentorship are set up to give news developers exposure to and experience of working in an open source community while working on a real project.

However, I decided to move with CNCF: Kubernetes just because I was more interested in the CNCF community rather than Linux Kernel. No doubt I woke up the whole night to complete the tasks of the [OpenAPS](https://openaps.org/) application for getting selected.

## How did I come to know about the LFX Mentorship Program?
I learned about the LFX mentorship program (then known as Community Bridge Mentorship) from [Parthvi](https://linkedin.com/in/valaparthvi), a neighbour (who has been standing by me whenever needed since my freshman year), and her friend [Himadri](https://www.linkedin.com/in/himadrics/). So, networking with people plays an important role here, in my case.

Many a time, I am being asked the question,

> “What do you think was the key to your selection?”

Here, I would love to put up [Davanum Srinivas](https://www.linkedin.com/in/davanum/)’s words:

> One attribute that is very helpful in open-source specifically is persistence/patience and the ability to stick to something. It takes time to build trust with whichever group of people whether in K8s SIGs or in other communities. There is plenty of stuff to do and not enough hands/brains to break things into bite-size chunks or to mentor enough folks who can then do the same. It’s not that people are unwilling to do things like that; it’s just that everyone is overwhelmed and exhausted especially in the last 2 years. So please pick something, and stick to it to the best of your ability (remembers a famous saying from Kennedy … about “country”).

## About Kubernetes Gateway API
The Gateway API is a part of the [SIG Network](https://github.com/kubernetes/community/tree/master/sig-network), and this [repository](https://github.com/kubernetes-sigs/gateway-api) contains the specification and Custom Resource Definitions (CRDs).

To know more about how Kubernetes is evolved in networking with Gateway API, you can visit: [kubernetes.io/blog](https://kubernetes.io/blog/2021/04/22/evolving-kubernetes-networking-with-the-gateway-api/)

### Let’s discuss the project!
The official LFX project link: [mentorship](https://mentorship.lfx.linuxfoundation.org/project/0e4c9797-2dc5-4621-b46a-f1b7371a2495)

Also, you can check out the [issue](https://github.com/kubernetes-sigs/gateway-api/issues/1003) in the project repository.

After going through both of the above links, you might get an idea of what I have worked on! If not, then let me explain you in brief.

The Gateway API project documentation has grown quickly and organically, and as a result is lacking overarching structure and clarity. So, I need to perform a docs assessment with the aim to:

- Measure against the CNCF’s standards for documentation
- Recommend areas to improve
- Provide examples of great documentation as reference
- Identify key areas which will need the largest improvement

The process goes like drafting an initial assessment, send it to CNCF techdocs team for a review along with the project maintainers and schedule a zoom meeting to discuss with them. After addressing all the suggestions made by the reviewers, submit a PR to the [techdocs](https://github.com/cncf/techdocs) repository.

In the middle of this mentorship, I received some good feedbacks from the mentors —

![Nick: Initial week feedback](https://miro.medium.com/max/1052/1*IJv_n-rSoxsbe2N-SZW4gA.png)

![Nate: Initial week feedback](https://miro.medium.com/max/656/1*ZQCgH3rif9qv30WycTFXjw.png)

Basically, I need to work on three areas as the assessment is divided into:

- Project documentation: for end users of the project; aimed at people who intend to use it
- Contributor documentation: for new and existing contributors to the project
- Website: branding, website structure, and maintainability

Each section rates content based on different [criteria](https://github.com/cncf/techdocs/blob/main/assessments/criteria.md).

Finally, after working in the loop several times, I have received great feedbacks from the mentors and the community finishing up my work.

![Appreciation after finishing project](https://miro.medium.com/max/1400/1*HBPCe6h8PgM5Be3c2E6W9Q.png)

## Scope for Improvement
Even after completing the LFX project work, I would like to implement the recommendations given in the assessment. So currently, we are having discussions on that. Looking onto my question regarding the migration plan, Nick replied:

> The goals for drawing up that should be:
>
>- Once we are moving, understand how we can version the site. How does the versioning that upstream Kubernetes does work? Is it a plugin, a workflow? It looks like it uses a subdomain for the version, can we do that as well, or do we need to do something else?
>
>- Now as we know how the versioning works, we can start sorting out theming etc, and understanding how that works. I think that we want to keep something that looks similar to what we have now.
>
>As soon as, we have answers to all of those questions, we need to write them up into a doc, and bring that to a Gateway API meeting for the community to discuss.

I will continue to volunteer on this.

## Is it difficult to get accepted into this?
Definitely not!

I started checking out the participating projects just a few weeks before the applications started and I did not have any sort of professional-level experience, but I was able to make it through.

Personally, I think the only requirements for one to get accepted into the LFX CNCF Program are willingness to learn, patience, open to network, and, willing to give back to the community. That summarises the important skills for one to contribute in open source.

**NOTE**: For the CNCF organziation, all project ideas get listed on GitHub [cncf/mentoring](https://github.com/cncf/mentoring/tree/main/lfx-mentorship) repository.

## Graduation & concluding it all
Wowww!! Eventually, after 12 weeks, the time really flies. I didn’t want this program to end. But every good thing comes to an end. I successfully graduated from the program —

![Graduated](https://miro.medium.com/max/1150/1*bUuVGDP9-Q_9cZdIzp-wcg.png)

And that’s a wrap, what an amazing journey it has been, thank you so much for continuing reading this long on my journey as an LFX mentee for CNCF: Kubernetes.

I would like to express my gratitude to my mentor [Nate](https://www.linkedin.com/in/nate-double-u/) and [Nick](https://www.linkedin.com/in/youngnickinsyd/) for being such amazing support throughout the project. Additionally, a big thank you to Rob, one who helped me to understand the project issues & how to resolve them apart from the documentation.

Heartfelt thanks to the Kubernetes, LFX, and CNCF community as well without whom neither this project nor this program could have been possible.

The link to the completed project is [here](https://github.com/cncf/techdocs/blob/main/assessments/0006-gateway-api.md) and if you have any feedback or questions, feel free to reach out to me on [LinkedIn](https://www.linkedin.com/in/meha-bhalodiya) or [Twitter](https://twitter.com/mehabhalodiya) and I will be glad to talk and help.

