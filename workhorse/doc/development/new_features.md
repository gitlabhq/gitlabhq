## Adding new features to Workhorse

GitLab Workhorse is a smart reverse proxy for GitLab. It handles
"long" HTTP requests such as file downloads, file uploads, Git
push/pull and Git archive downloads.

Workhorse itself is not a feature, but there are [several features in GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/master/workhorse/doc/architecture/gitlab_features.md) that would not work efficiently without Workhorse.

At a first glance, it may look like Workhorse is just a pipeline for processing HTTP streams so that you can reduce the amount of logic in your Ruby on Rails controller, but there are good reasons to avoid treating it like that.

Engineers embarking on the quest of offloading a feature to Workhorse often find that the endeavor is much higher than what originally anticipated. In part because of the new programming language (only a few engineers at GitLab are Go developers), in part because of the demanding requirements for Workhorse. Workhorse is stateless, memory and disk usage must be kept under tight control, and the request should not be slowed down in the process.

## Can I add a new feature to Workhorse?

We suggest to follow this route only if absolutely necessary and no other options are available.

Splitting a feature between the Rails code-base and Workhorse is deliberately choosing to introduce technical debt. It adds complexity to the system and coupling between the two components.

* Building features using Workhorse has a considerable complexity cost, so you should prefer designs based on Rails requests and Sidekiq jobs.
* Even when using Rails+Sidekiq is "more work" than using Rails+Workhorse, Rails+Sidekiq is easier to maintain in the long term because Workhorse is unique to GitLab while Rails+Sidekiq is an industry standard.
* For "global" behaviors around web requests consider using a Rack middleware instead of Workhorse.
* Generally speaking, we should only use Rails+Workhorse if the HTTP client expects behavior that is not reasonable to implement in Rails, like "long" requests.

## What is a "long" request?

There is one order of magnitude between Workhorse and puma RAM usage. Having connection open for a period longer than milliseconds is a problem because of the amount of RAM it monopolizes once it reaches the Ruby on Rails controller.

So far we identified two classes of "long" requests: data transfers and HTTP long polling.

`git push`, `git pull`, uploading or downloading an artifact, the CI runner waiting for a new job are all good examples of long requests.

With the rise of cloud-native installations, Workhorse's feature-set was extended to add object storage direct-upload, to get rid of the shared Network File System (NFS) drives.

In 2020 @nolith presented at FOSDEM a talk titled [_Speed up the monolith. Building a smart reverse proxy in Go_](https://archive.fosdem.org/2020/schedule/event/speedupmonolith/).
You can watch the recording for more details on the history of Workhorse and the NFS removal.

[Uploads development documentation]( https://docs.gitlab.com/ee/development/uploads.html)
contains the most common use-cases for adding a new type of upload and may answer all of your questions.

If you still think we should add a new feature to Workhorse, please open an issue explaining **what you want to implement** and **why it can't be implemented in our ruby code-base**. Workhorse maintainers will be happy to help you assessing the situation.

