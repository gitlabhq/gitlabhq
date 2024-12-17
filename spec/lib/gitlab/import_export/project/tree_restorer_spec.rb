# frozen_string_literal: true

require 'spec_helper'

def match_mr1_note(content_regex)
  MergeRequest.find_by(title: 'MR1').notes.find { |n| n.note.match(/#{content_regex}/) }
end

RSpec.describe Gitlab::ImportExport::Project::TreeRestorer, feature_category: :importers do
  include ImportExport::CommonUtil
  using RSpec::Parameterized::TableSyntax

  let(:shared) { project.import_export_shared }

  RSpec.shared_examples 'project tree restorer work properly' do
    describe 'restore project tree' do
      before_all do
        # Using an admin for import, so we can check assignment of existing members
        @user = create(:admin)
        @existing_members = [
          create(:user, email: 'bernard_willms@gitlabexample.com'),
          create(:user, email: 'saul_will@gitlabexample.com')
        ]

        RSpec::Mocks.with_temporary_scope do
          @project = create(:project, :repository, :builds_enabled, :issues_disabled, name: 'project', path: 'project')
          @shared = @project.import_export_shared

          stub_all_feature_flags

          setup_import_export_config('complex')
          setup_reader

          allow_any_instance_of(Repository).to receive(:fetch_source_branch!).and_return(true)
          allow_any_instance_of(Gitlab::Git::Repository).to receive(:branch_exists?).and_return(false)

          expect(@shared).not_to receive(:error)
          allow_any_instance_of(Gitlab::Git::Repository).to receive(:create_branch)

          project_tree_restorer = described_class.new(user: @user, shared: @shared, project: @project)

          @restored_project_json = Gitlab::ExclusiveLease.skipping_transaction_check do
            project_tree_restorer.restore
          end
        end
      end

      context 'JSON' do
        it 'restores models based on JSON' do
          expect(@restored_project_json).to be_truthy
        end

        it 'restore correct project features' do
          project = Project.find_by_path('project')

          expect(project.project_feature.issues_access_level).to eq(ProjectFeature::PRIVATE)
          expect(project.project_feature.builds_access_level).to eq(ProjectFeature::PRIVATE)
          expect(project.project_feature.snippets_access_level).to eq(ProjectFeature::PRIVATE)
          expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::PRIVATE)
          expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::PRIVATE)
        end

        it 'has the project description' do
          expect(Project.find_by_path('project').description).to eq('Nisi et repellendus ut enim quo accusamus vel magnam.')
        end

        it 'has the project merge commit message template' do
          expect(Project.find_by_path('project').merge_commit_template).to eq('merge commit message template')
        end

        it 'has the project squash commit message template' do
          expect(Project.find_by_path('project').squash_commit_template).to eq('squash commit message template')
        end

        it 'has the same label associated to two issues' do
          expect(ProjectLabel.find_by_title('test2').issues.count).to eq(2)
        end

        it 'has milestones associated to two separate issues' do
          expect(Milestone.find_by_description('test milestone').issues.count).to eq(2)
        end

        context 'when importing a project with cached_markdown_version and note_html' do
          context 'for an Issue' do
            it 'does not import note_html' do
              note_content = 'Quo reprehenderit aliquam qui dicta impedit cupiditate eligendi'
              issue_note = Issue.find_by(description: 'Aliquam enim illo et possimus.').notes.find { |n| n.note.match(/#{note_content}/) }

              expect(issue_note.note_html).to match(/#{note_content}/)
            end
          end

          context 'for a Merge Request' do
            it 'does not import note_html' do
              note_content = 'Sit voluptatibus eveniet architecto quidem'
              merge_request_note = match_mr1_note(note_content)

              expect(merge_request_note.note_html).to match(/#{note_content}/)
            end
          end

          context 'merge request system note metadata' do
            it 'restores title action for unmark wip' do
              merge_request_note = match_mr1_note('unmarked as a \\*\\*Work In Progress\\*\\*')

              expect(merge_request_note.noteable_type).to eq('MergeRequest')
              expect(merge_request_note.system).to eq(true)
              expect(merge_request_note.system_note_metadata.action).to eq('title')
              expect(merge_request_note.system_note_metadata.commit_count).to be_nil
            end

            it 'restores commit action and commit count for pushing 3 commits' do
              merge_request_note = match_mr1_note('added 3 commits')

              expect(merge_request_note.noteable_type).to eq('MergeRequest')
              expect(merge_request_note.system).to eq(true)
              expect(merge_request_note.system_note_metadata.action).to eq('commit')
              expect(merge_request_note.system_note_metadata.commit_count).to eq(3)
            end
          end
        end

        it 'does not import ci config path' do
          expect(@project.ci_config_path).to be_nil
        end

        it 'creates a valid pipeline note' do
          expect(Ci::Pipeline.find_by_sha('sha-notes').notes).not_to be_empty
        end

        it 'pipeline has the correct user ID' do
          expect(Ci::Pipeline.find_by_sha('sha-notes').user_id).to eq(@user.id)
        end

        it 'restores pipelines with missing ref' do
          expect(Ci::Pipeline.where(ref: nil)).not_to be_empty
        end

        it 'restores pipeline for merge request' do
          pipeline = Ci::Pipeline.find_by_sha('048721d90c449b244b7b4c53a9186b04330174ec')

          expect(pipeline).to be_valid
          expect(pipeline.tag).to be_falsey
          expect(pipeline.source).to eq('merge_request_event')
          expect(pipeline.merge_request.id).to be > 0
          expect(pipeline.merge_request.target_branch).to eq('feature')
          expect(pipeline.merge_request.source_branch).to eq('feature_conflict')
          expect(pipeline.merge_request.merge_when_pipeline_succeeds).to eq(false)
        end

        it 'restores pipelines based on ascending id order' do
          expected_ordered_shas = %w[
            2ea1f3dec713d940208fb5ce4a38765ecb5d3f73
            ce84140e8b878ce6e7c4d298c7202ff38170e3ac
            048721d90c449b244b7b4c53a9186b04330174ec
            sha-notes
            5f923865dde3436854e9ceb9cdb7815618d4e849
            d2d430676773caa88cdaf7c55944073b2fd5561a
            2ea1f3dec713d940208fb5ce4a38765ecb5d3f73
            1b6c4f044c63217d1ed06e514c84d22871bed912
            ded178474ef2ba1f80a9964ba15da3ddb3cf664b
            fd459e5c514d70dc525c5e70990ca5e0debb3105
          ]

          project = Project.find_by_path('project')

          project.ci_pipelines.order(:id).each_with_index do |pipeline, i|
            expect(pipeline['sha']).to eq expected_ordered_shas[i]
          end
        end

        it 'restores pipeline metadata' do
          pipeline = Ci::Pipeline.find_by_sha('sha-notes')
          pipeline_metadata = pipeline.pipeline_metadata

          expect(pipeline_metadata.name).to eq('Build pipeline')
          expect(pipeline_metadata.pipeline_id).to eq(pipeline.id)
          expect(pipeline_metadata.project_id).to eq(pipeline.project_id)
        end

        it 'preserves work_item_type for all issues (legacy with issue_type and new with work_item_type)',
          :aggregate_failures do
          task_issue1 = Issue.find_by(title: 'task by issue_type')
          task_issue2 = Issue.find_by(title: 'task by both attributes')
          incident_issue = Issue.find_by(title: 'incident by work_item_type')
          issue_with_invalid_type = Issue.find_by(title: 'invalid issue type')
          issue_type = WorkItems::Type.default_by_type(:issue)
          task_type = WorkItems::Type.default_by_type(:task)

          expect(task_issue1.work_item_type).to eq(task_type)
          expect(task_issue2.work_item_type).to eq(task_type)
          expect(incident_issue.work_item_type).to eq(WorkItems::Type.default_by_type(:incident))
          expect(issue_with_invalid_type.work_item_type).to eq(issue_type)

          other_issue_types = Issue.preload(:work_item_type).where.not(
            id: [task_issue1.id, task_issue2.id, incident_issue.id, issue_with_invalid_type]
          ).map(&:work_item_type)

          expect(other_issue_types).to all(eq(issue_type))
        end

        it 'preserves updated_at on issues' do
          issue = Issue.find_by(description: 'Aliquam enim illo et possimus.')

          expect(issue.reload.updated_at.to_s).to eq('2016-06-14 15:02:47 UTC')
        end

        it 'has multiple issue assignees' do
          expect(Issue.find_by(title: 'Voluptatem').assignees).to contain_exactly(@user, *@existing_members)
          expect(Issue.find_by(title: 'Issue without assignees').assignees).to be_empty
        end

        it 'restores timelogs for issues' do
          timelog = Issue.find_by(title: 'issue_with_timelogs').timelogs.last

          aggregate_failures do
            expect(timelog.time_spent).to eq(72000)
            expect(timelog.spent_at).to eq("2019-12-27T00:00:00.000Z")
          end
        end

        it 'contains the merge access levels on a protected branch' do
          expect(ProtectedBranch.first.merge_access_levels).not_to be_empty
        end

        it 'contains the push access levels on a protected branch' do
          expect(ProtectedBranch.first.push_access_levels).not_to be_empty
        end

        it 'contains the create access levels on a protected tag' do
          expect(ProtectedTag.first.create_access_levels).not_to be_empty
        end

        it 'restores issue resource label events' do
          expect(Issue.find_by(title: 'Voluptatem').resource_label_events).not_to be_empty
        end

        it 'restores issue resource milestone events' do
          expect(Issue.find_by(title: 'Voluptatem').resource_milestone_events).not_to be_empty
        end

        it 'restores issue resource state events' do
          expect(Issue.find_by(title: 'Voluptatem').resource_state_events).not_to be_empty
        end

        it 'restores merge requests resource label events' do
          expect(MergeRequest.find_by(title: 'MR1').resource_label_events).not_to be_empty
        end

        it 'restores merge request resource milestone events' do
          expect(MergeRequest.find_by(title: 'MR1').resource_milestone_events).not_to be_empty
        end

        it 'restores merge request resource state events' do
          expect(MergeRequest.find_by(title: 'MR1').resource_state_events).not_to be_empty
        end

        it 'restores suggestion' do
          note = Note.find_by("note LIKE 'Saepe asperiores exercitationem non dignissimos laborum reiciendis et ipsum%'")

          expect(note.suggestions.count).to eq(1)
          expect(note.suggestions.first.from_content).to eq("Original line\n")
        end

        context 'event at forth level of the tree' do
          let(:event) { Event.find_by(action: 6) }

          it 'restores the event' do
            expect(event).not_to be_nil
          end

          it 'has the action' do
            expect(event.action).not_to be_nil
          end

          it 'event belongs to note, belongs to merge request, belongs to a project' do
            expect(event.note.noteable.project).not_to be_nil
          end
        end

        it 'has the correct data for merge request diff files' do
          expect(MergeRequestDiffFile.where.not(diff: nil).count).to eq(55)
        end

        it 'has the correct data for merge request diff commits' do
          expect(MergeRequestDiffCommit.count).to eq(77)
        end

        it 'assigns committer and author details to all diff commits' do
          MergeRequestDiffCommit.all.each do |commit|
            expect(commit.commit_author_id).not_to be_nil
            expect(commit.committer_id).not_to be_nil
          end
        end

        it 'assigns the correct commit users to different diff commits' do
          commit1 = MergeRequestDiffCommit
            .find_by(sha: '0b4bc9a49b562e85de7cc9e834518ea6828729b9')

          commit2 = MergeRequestDiffCommit
            .find_by(sha: 'a4e5dfebf42e34596526acb8611bc7ed80e4eb3f')

          expect(commit1.commit_author.name).to eq('Dmitriy Zaporozhets')
          expect(commit1.commit_author.email).to eq('dmitriy.zaporozhets@gmail.com')

          expect(commit2.commit_author.name).to eq('James Lopez')
          expect(commit2.commit_author.email).to eq('james@jameslopez.es')
        end

        it 'has the correct data for merge request latest_merge_request_diff' do
          MergeRequest.find_each do |merge_request|
            expect(merge_request.latest_merge_request_diff_id).to eq(merge_request.merge_request_diffs.maximum(:id))
          end
        end

        it 'sets auto merge to false for all merge requests' do
          MergeRequest.find_each do |merge_request|
            expect(merge_request.merge_when_pipeline_succeeds).to eq(false)
          end
        end

        it 'has multiple merge request assignees' do
          expect(MergeRequest.find_by(title: 'MR1').assignees).to contain_exactly(@user, *@existing_members)
          expect(MergeRequest.find_by(title: 'MR2').assignees).to be_empty
        end

        it 'has multiple merge request reviewers' do
          expect(MergeRequest.find_by(title: 'MR1').reviewers).to contain_exactly(@user, *@existing_members)
          expect(MergeRequest.find_by(title: 'MR2').reviewers).to be_empty
        end

        it 'has labels associated to label links, associated to issues' do
          expect(Label.first.label_links.first.target).not_to be_nil
        end

        it 'has project labels' do
          expect(ProjectLabel.count).to eq(3)
          expect(ProjectLabel.pluck(:group_id).compact).to be_empty
        end

        it 'has merge request approvals' do
          expect(MergeRequest.find_by(title: 'MR1').approvals.pluck(:user_id)).to contain_exactly(@user.id, *@existing_members.map(&:id))
          expect(MergeRequest.find_by(title: 'MR2').approvals).to be_empty
        end

        it 'has no group labels' do
          expect(GroupLabel.count).to eq(0)
        end

        it 'has issue boards' do
          expect(Project.find_by_path('project').boards.count).to eq(1)
        end

        it 'has lists associated with the issue board' do
          expect(Project.find_by_path('project').boards.find_by_name('TestBoardABC').lists.count).to eq(3)
        end

        it 'has a project feature' do
          expect(@project.project_feature).not_to be_nil
        end

        it 'has custom attributes' do
          expect(@project.custom_attributes.count).to eq(2)
        end

        it 'has badges' do
          expect(@project.project_badges.count).to eq(2)
        end

        it 'has snippets' do
          expect(@project.snippets.count).to eq(1)
        end

        it 'has award emoji for a snippet' do
          award_emoji = @project.snippets.first.award_emoji

          expect(award_emoji.map(&:name)).to contain_exactly(AwardEmoji::THUMBS_UP, 'coffee')
        end

        it 'snippet has notes' do
          expect(@project.snippets.first.notes.count).to eq(1)
        end

        it 'snippet has award emojis on notes' do
          award_emoji = @project.snippets.first.notes.first.award_emoji.first

          expect(award_emoji.name).to eq(AwardEmoji::THUMBS_UP)
        end

        it 'restores `ci_cd_settings` : `group_runners_enabled` setting' do
          expect(@project.ci_cd_settings.group_runners_enabled?).to eq(false)
        end

        it 'restores `auto_devops`' do
          expect(@project.auto_devops_enabled?).to eq(true)
          expect(@project.auto_devops.deploy_strategy).to eq('continuous')
        end

        it 'restores zoom meetings' do
          meetings = @project.issues.first.zoom_meetings

          expect(meetings.count).to eq(1)
          expect(meetings.first.url).to eq('https://zoom.us/j/123456789')
        end

        it 'restores sentry issues' do
          sentry_issue = @project.issues.first.sentry_issue

          expect(sentry_issue.sentry_issue_identifier).to eq(1234567891)
        end

        it 'has award emoji for an issue' do
          award_emoji = @project.issues.first.award_emoji.first

          expect(award_emoji.name).to eq('musical_keyboard')
        end

        it 'has award emoji for a note in an issue' do
          award_emoji = @project.issues.first.notes.first.award_emoji.first

          expect(award_emoji.name).to eq('clapper')
        end

        it 'restores container_expiration_policy' do
          policy = Project.find_by_path('project').container_expiration_policy

          aggregate_failures do
            expect(policy).to be_an_instance_of(ContainerExpirationPolicy)
            expect(policy).to be_persisted
            expect(policy.cadence).to eq('3month')
          end
        end

        it 'restores error_tracking_setting' do
          setting = @project.error_tracking_setting

          aggregate_failures do
            expect(setting.api_url).to eq("https://gitlab.example.com/api/0/projects/sentry-org/sentry-project")
            expect(setting.project_name).to eq("Sentry Project")
            expect(setting.organization_name).to eq("Sentry Org")
          end
        end

        it 'restores external pull requests' do
          external_pr = @project.external_pull_requests.last

          aggregate_failures do
            expect(external_pr.pull_request_iid).to eq(4)
            expect(external_pr.source_branch).to eq("feature")
            expect(external_pr.target_branch).to eq("master")
            expect(external_pr.status).to eq("open")
          end
        end

        it 'restores pipeline schedules' do
          pipeline_schedule = @project.pipeline_schedules.last

          aggregate_failures do
            expect(pipeline_schedule.description).to eq('Schedule Description')
            expect(pipeline_schedule.ref).to eq('master')
            expect(pipeline_schedule.cron).to eq('0 4 * * 0')
            expect(pipeline_schedule.cron_timezone).to eq('UTC')
            expect(pipeline_schedule.active).to eq(false)
            expect(pipeline_schedule.owner_id).to eq(@user.id)
          end
        end

        context 'restores releases' do
          it 'with links & milestones' do
            release = @project.releases.last
            link = release.links.last

            aggregate_failures do
              expect(release.tag).to eq('release-1.2')
              expect(release.description).to eq('Some release notes')
              expect(release.name).to eq('release-1.2')
              expect(release.sha).to eq('903de3a8bd5573f4a049b1457d28bc1592ba6bf9')
              expect(release.released_at).to eq('2019-12-27T10:17:14.615Z')
              expect(release.milestone_releases.count).to eq(1)
              expect(release.milestone_releases.first.milestone.title).to eq('test milestone')

              expect(link.url).to eq('http://localhost/namespace6/project6/-/jobs/140463678/artifacts/download')
              expect(link.name).to eq('release-1.2.dmg')
            end
          end

          context 'with author' do
            it 'as ghost user when imported release author is empty' do
              release = @project.releases.first

              aggregate_failures do
                expect(release.tag).to eq('release-1.0')
                expect(release.author_id).to eq(Users::Internal.ghost.id)
              end
            end

            it 'as existing member when imported release author is matched with existing user' do
              release = @project.releases.second

              aggregate_failures do
                expect(release.tag).to eq('release-1.1')
                expect(release.author_id).to eq(@existing_members.first.id)
              end
            end

            it 'as import user when imported release author cannot be matched' do
              release = @project.releases.last

              aggregate_failures do
                expect(release.tag).to eq('release-1.2')
                expect(release.author_id).to eq(@user.id)
              end
            end
          end
        end

        context 'Merge requests' do
          it 'always has the new project as a target' do
            expect(MergeRequest.find_by_title('MR1').target_project).to eq(@project)
          end

          it 'has the same source project as originally if source/target are the same' do
            expect(MergeRequest.find_by_title('MR1').source_project).to eq(@project)
          end

          it 'has the new project as target if source/target differ' do
            expect(MergeRequest.find_by_title('MR2').target_project).to eq(@project)
          end

          it 'has no source if source/target differ' do
            expect(MergeRequest.find_by_title('MR2').source_project_id).to be_nil
          end

          it 'has award emoji' do
            award_emoji = MergeRequest.find_by_title('MR1').award_emoji

            expect(award_emoji.map(&:name)).to contain_exactly(AwardEmoji::THUMBS_UP, 'drum')
          end

          context 'notes' do
            it 'has award emoji' do
              merge_request_note = match_mr1_note('Sit voluptatibus eveniet architecto quidem')
              award_emoji = merge_request_note.award_emoji.first

              expect(award_emoji.name).to eq('tada')
            end

            it 'has diff note diff file' do
              merge_request_note = match_mr1_note('MR1 diff note')
              note_diff_file = merge_request_note.note_diff_file

              expect(note_diff_file.diff).to eq("@@ -14,3 +14,18 @@\n 1")
            end
          end
        end

        context 'tokens are regenerated' do
          it 'has new CI trigger tokens' do
            expect(Ci::Trigger.where(token: %w[cdbfasdf44a5958c83654733449e585 33a66349b5ad01fc00174af87804e40]))
              .to be_empty
          end

          it 'has a new CI build token' do
            expect(Ci::Build.find_by_token('abcd')).to be_nil
          end
        end

        context 'has restored the correct number of records' do
          it 'has the correct number of merge requests' do
            expect(@project.merge_requests.size).to eq(9)
          end

          it 'does not restore triggers' do
            expect(@project.triggers.size).to eq(0)
          end

          it 'has the correct number of pipelines and statuses' do
            expect(@project.ci_pipelines.size).to eq(10)

            @project.ci_pipelines.order(:id).zip([2, 0, 2, 3, 2, 8, 0, 0, 0, 0])
              .each do |(pipeline, expected_status_size)|
              expect(pipeline.statuses.size).to eq(expected_status_size)
            end
          end
        end

        context 'when restoring hierarchy of pipeline, stages and jobs' do
          context 'pipelines' do
            it 'restores pipelines' do
              expect(Ci::Pipeline.all.count).to be 10
            end

            it 'marks cancelable pipelines as canceled' do
              expect(Ci::Pipeline.where(status: 'canceled').count).to eq 7
            end
          end

          context 'stages' do
            it 'restores pipeline stages' do
              expect(Ci::Stage.all.count).to be 7
            end

            it 'marks cancelable stages as canceled' do
              expect(Ci::Stage.where(status: 'canceled').count).to eq 6
            end

            it 'correctly restores association between stage and a pipeline' do
              expect(Ci::Stage.all).to all(have_attributes(pipeline_id: a_value > 0))
            end
          end

          context 'builds' do
            it 'restores builds' do
              expect(Ci::Build.all.count).to be 7
            end

            it 'marks cancelable builds as canceled' do
              expect(Ci::Build.where(status: 'canceled').count).to eq 3
            end
          end

          context 'bridges' do
            it 'restores bridges' do
              expect(Ci::Bridge.all.count).to be 5
            end

            it 'marks cancelable bridges as canceled' do
              expect(Ci::Bridge.where(status: 'canceled').count).to eq 4
            end
          end

          context 'generic commit statuses' do
            it 'restores generic commit statuses' do
              expect(GenericCommitStatus.all.count).to be 3
            end

            it 'marks cancelable generic commit statuses as canceled' do
              expect(GenericCommitStatus.where(status: 'canceled').count).to eq 2
            end
          end

          it 'correctly restores association between a stage and a job' do
            expect(CommitStatus.all).to all(have_attributes(stage_id: a_value > 0))
          end

          it 'correctly restores association between a pipeline and a job' do
            expect(CommitStatus.all).to all(have_attributes(pipeline_id: a_value > 0))
          end

          it 'restores a Hash for CommitStatus options' do
            expect(CommitStatus.all.map(&:options).compact).to all(be_a(Hash))
          end

          it 'restores external pull request for the restored pipeline' do
            pipeline_with_external_pr = @project.ci_pipelines.find_by(source: 'external_pull_request_event')

            expect(pipeline_with_external_pr.external_pull_request).to be_persisted
          end

          it 'has no import failures' do
            expect(@project.import_failures.size).to eq 0
          end
        end

        it 'restores commit notes' do
          expect(@project.commit_notes.count).to eq(3)
        end
      end
    end

    shared_examples 'restores group correctly' do |**results|
      it 'has group label' do
        expect(project.group.labels.size).to eq(results.fetch(:labels, 0))
        expect(project.group.labels.where(type: "GroupLabel").where.not(project_id: nil).count).to eq(0)
      end

      it 'has group milestone' do
        expect(project.group.milestones.size).to eq(results.fetch(:milestones, 0))
      end

      it 'has the correct visibility level' do
        # INTERNAL in the `project.json`, group's is PRIVATE
        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when expect tree structure is not present in the export path' do
      let(:user) { create(:user) }
      let_it_be(:project) { create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }

      it 'fails to restore the project' do
        result = described_class.new(user: user, shared: shared, project: project).restore

        expect(result).to eq(false)
        expect(shared.errors).to include('invalid import format')
      end
    end

    context 'Light JSON' do
      let(:user) { create(:user) }
      let!(:project) { create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }
      let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }
      let(:restored_project_json) { project_tree_restorer.restore }

      context 'with a simple project' do
        before do
          setup_import_export_config('light')
          setup_reader

          expect(restored_project_json).to eq(true)
        end

        it 'issue system note metadata restored successfully' do
          note_content = 'created merge request !1 to address this issue'
          note = project.issues.first.notes.find { |n| n.note.match(/#{note_content}/) }

          expect(note.noteable_type).to eq('Issue')
          expect(note.system).to eq(true)
          expect(note.system_note_metadata.action).to eq('merge')
          expect(note.system_note_metadata.commit_count).to be_nil
        end

        context 'when there is an existing build with build token' do
          before do
            create(:ci_build).tap do |job|
              job.set_token('abcd')
              job.save!
            end
          end

          it_behaves_like 'restores project successfully',
            issues: 1,
            labels: 2,
            label_with_priorities: 'A project label',
            milestones: 1,
            first_issue_labels: 1
        end
      end

      context 'multiple pipelines reference the same external pull request' do
        before do
          setup_import_export_config('multi_pipeline_ref_one_external_pr')
          setup_reader

          expect(restored_project_json).to eq(true)
        end

        it_behaves_like 'restores project successfully',
          issues: 0,
          labels: 0,
          milestones: 0,
          ci_pipelines: 2,
          external_pull_requests: 1,
          import_failures: 0

        it 'restores external pull request for the restored pipelines' do
          external_pr = project.external_pull_requests.first

          project.ci_pipelines.each do |pipeline_with_external_pr|
            expect(pipeline_with_external_pr.external_pull_request).to be_persisted
            expect(pipeline_with_external_pr.external_pull_request).to eq(external_pr)
          end
        end
      end

      context 'when post import action throw non-retriable exception' do
        let(:exception) { StandardError.new('post_import_error') }

        before do
          setup_import_export_config('light')
          setup_reader

          expect(project).to receive(:merge_requests).and_call_original
          expect(project).to receive(:merge_requests).and_raise(exception)
        end

        it 'report post import error' do
          expect(restored_project_json).to eq(false)
          expect(shared.errors).to include('post_import_error')
        end
      end

      context 'when post import action throw retriable exception one time' do
        let(:exception) { GRPC::DeadlineExceeded.new }

        before do
          setup_import_export_config('light')
          setup_reader

          expect(project).to receive(:merge_requests).and_call_original
          expect(project).to receive(:merge_requests).and_raise(exception)
          expect(project).to receive(:merge_requests).and_call_original
          expect(restored_project_json).to eq(true)
        end

        it_behaves_like 'restores project successfully',
          issues: 1,
          labels: 2,
          label_with_priorities: 'A project label',
          milestones: 1,
          first_issue_labels: 1,
          import_failures: 1

        it 'records the failures in the database' do
          import_failure = ImportFailure.last

          expect(import_failure.project_id).to eq(project.id)
          expect(import_failure.relation_key).to be_nil
          expect(import_failure.relation_index).to be_nil
          expect(import_failure.exception_class).to eq('GRPC::DeadlineExceeded')
          expect(import_failure.exception_message).to be_present
          expect(import_failure.correlation_id_value).not_to be_empty
          expect(import_failure.created_at).to be_present
        end
      end

      context 'when the project has overridden params in import data' do
        before do
          setup_import_export_config('light')
          setup_reader
        end

        it 'handles string versions of visibility_level' do
          # Project needs to be in a group for visibility level comparison
          # to happen
          group = create(:group)
          group.add_maintainer(user)
          project.group = group

          project.create_import_data(data: { override_params: { visibility_level: Gitlab::VisibilityLevel::INTERNAL.to_s } })

          expect(restored_project_json).to eq(true)
          expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'overwrites the params stored in the JSON' do
          project.create_import_data(data: { override_params: { description: "Overridden" } })

          expect(restored_project_json).to eq(true)
          expect(project.description).to eq("Overridden")
        end

        it 'does not allow setting params that are excluded from import_export settings' do
          original_value = project.lfs_enabled?

          project.create_import_data(data: { override_params: { lfs_enabled: !original_value } })

          expect(restored_project_json).to eq(true)
          expect(project.lfs_enabled).to eq(original_value)
        end

        it 'overrides project feature access levels' do
          access_level_keys = ProjectFeature.available_features.map { |feature| ProjectFeature.access_level_attribute(feature) }
          disabled_access_levels = access_level_keys.index_with { 'disabled' }

          project.create_import_data(data: { override_params: disabled_access_levels })

          expect(restored_project_json).to eq(true)

          aggregate_failures do
            access_level_keys.each do |key|
              expect(project.public_send(key)).to eq(ProjectFeature::DISABLED)
            end
          end
        end
      end

      context 'with a project that has a group' do
        let(:group) do
          create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE).tap do |g|
            g.add_maintainer(user)
          end
        end

        let!(:project) do
          create(
            :project,
            :builds_disabled,
            :issues_disabled,
            name: 'project',
            path: 'project',
            group: group
          )
        end

        before do
          setup_import_export_config('group')
          setup_reader

          expect(restored_project_json).to eq(true)
        end

        it_behaves_like 'restores project successfully',
          issues: 3,
          labels: 2,
          label_with_priorities: 'A project label',
          milestones: 2,
          first_issue_labels: 1

        it_behaves_like 'restores group correctly',
          labels: 0,
          milestones: 0,
          first_issue_labels: 1

        it 'restores issue states' do
          expect(project.issues.with_state(:closed).count).to eq(1)
          expect(project.issues.with_state(:opened).count).to eq(2)
        end
      end

      context 'with existing group models' do
        let(:group) { create(:group, maintainers: user) }
        let!(:project) do
          create(
            :project,
            :builds_disabled,
            :issues_disabled,
            name: 'project',
            path: 'project',
            group: group
          )
        end

        before do
          setup_import_export_config('light')
          setup_reader
        end

        it 'imports labels' do
          create(:group_label, name: 'Another label', group: project.group)

          expect_any_instance_of(Gitlab::ImportExport::Shared).not_to receive(:error)

          expect(restored_project_json).to eq(true)
          expect(project.labels.count).to eq(1)
        end

        it 'imports milestones' do
          create(:milestone, name: 'A milestone', group: project.group)

          expect_any_instance_of(Gitlab::ImportExport::Shared).not_to receive(:error)

          expect(restored_project_json).to eq(true)
          expect(project.group.milestones.count).to eq(1)
          expect(project.milestones.count).to eq(0)
        end
      end

      context 'with clashing milestones on IID' do
        let(:group) { create(:group, maintainers: user) }
        let!(:project) do
          create(
            :project,
            :builds_disabled,
            :issues_disabled,
            name: 'project',
            path: 'project',
            group: group
          )
        end

        before do
          setup_import_export_config('milestone-iid')
          setup_reader
        end

        it 'preserves the project milestone IID' do
          expect_any_instance_of(Gitlab::ImportExport::Shared).not_to receive(:error)

          expect(restored_project_json).to eq(true)
          expect(project.milestones.count).to eq(2)
          expect(Milestone.find_by_title('Another milestone').iid).to eq(1)
          expect(Milestone.find_by_title('Group-level milestone').iid).to eq(2)
        end
      end

      context 'with external authorization classification labels' do
        before do
          setup_import_export_config('light')
          setup_reader
        end

        it 'converts empty external classification authorization labels to nil' do
          project.create_import_data(data: { override_params: { external_authorization_classification_label: "" } })

          expect(restored_project_json).to eq(true)
          expect(project.external_authorization_classification_label).to be_nil
        end

        it 'preserves valid external classification authorization labels' do
          project.create_import_data(data: { override_params: { external_authorization_classification_label: "foobar" } })

          expect(restored_project_json).to eq(true)
          expect(project.external_authorization_classification_label).to eq("foobar")
        end
      end
    end

    context 'Minimal JSON' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:tree_hash) { { 'visibility_level' => visibility } }
      let(:restorer) do
        described_class.new(user: user, shared: shared, project: project)
      end

      describe 'visibility level' do
        before do
          setup_import_export_config('light')

          allow_next_instance_of(Gitlab::ImportExport::Json::NdjsonReader) do |relation_reader|
            allow(relation_reader).to receive(:consume_attributes).and_return(tree_hash)
          end
        end

        context 'no group visibility' do
          let(:visibility) { Gitlab::VisibilityLevel::PRIVATE }

          it 'uses the project visibility' do
            expect(restorer.restore).to eq(true)
            expect(restorer.project.visibility_level).to eq(visibility)
          end
        end

        context 'with restricted internal visibility' do
          describe 'internal project' do
            let(:visibility) { Gitlab::VisibilityLevel::INTERNAL }

            it 'uses private visibility' do
              stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

              expect(restorer.restore).to eq(true)
              expect(restorer.project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            end
          end
        end

        context 'with group visibility' do
          before do
            group = create(:group, visibility_level: group_visibility)
            group.add_members([user], GroupMember::MAINTAINER)
            project.update!(group: group)
          end

          context 'private group visibility' do
            let(:group_visibility) { Gitlab::VisibilityLevel::PRIVATE }
            let(:visibility) { Gitlab::VisibilityLevel::PUBLIC }

            it 'uses the group visibility' do
              expect(restorer.restore).to eq(true)
              expect(restorer.project.visibility_level).to eq(group_visibility)
            end
          end

          context 'public group visibility' do
            let(:group_visibility) { Gitlab::VisibilityLevel::PUBLIC }
            let(:visibility) { Gitlab::VisibilityLevel::PRIVATE }

            it 'uses the project visibility' do
              expect(restorer.restore).to eq(true)
              expect(restorer.project.visibility_level).to eq(visibility)
            end
          end

          context 'internal group visibility' do
            let(:group_visibility) { Gitlab::VisibilityLevel::INTERNAL }
            let(:visibility) { Gitlab::VisibilityLevel::PUBLIC }

            it 'uses the group visibility' do
              expect(restorer.restore).to eq(true)
              expect(restorer.project.visibility_level).to eq(group_visibility)
            end

            context 'with restricted internal visibility' do
              it 'sets private visibility' do
                stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

                expect(restorer.restore).to eq(true)
                expect(restorer.project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
              end
            end
          end
        end
      end

      context 'with project members' do
        let(:user) { create(:user, :admin) }
        let(:user2) { create(:user) }
        let(:project_members) do
          [
            [
              {
                "id" => 2,
                "access_level" => 40,
                "source_type" => "Project",
                "notification_level" => 3,
                "user" => {
                  "id" => user2.id,
                  "email" => user2.email,
                  "username" => 'test'
                }
              },
              0
            ]
          ]
        end

        before do
          project.add_maintainer(user)

          setup_import_export_config('light')

          allow_next_instance_of(Gitlab::ImportExport::Json::NdjsonReader) do |relation_reader|
            allow(relation_reader).to receive(:consume_relation).and_call_original

            allow(relation_reader).to receive(:consume_relation)
              .with('project', 'project_members')
              .and_return(project_members)
          end
        end

        it 'restores project members' do
          restorer.restore

          expect(project.members.map(&:user)).to contain_exactly(user, user2)
        end
      end
    end

    context 'JSON with invalid records' do
      subject(:restored_project_json) { project_tree_restorer.restore }

      let(:user) { create(:user) }
      let!(:project) { create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }
      let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }
      let(:project_fixture) { 'with_invalid_records' }

      before do
        setup_import_export_config(project_fixture)
        setup_reader

        subject
      end

      context 'when failures occur because a relation fails to be processed' do
        it_behaves_like 'restores project successfully',
          issues: 0,
          labels: 0,
          label_with_priorities: nil,
          milestones: 1,
          first_issue_labels: 0,
          import_failures: 1

        it 'records the failures in the database' do
          import_failure = ImportFailure.last

          expect(import_failure.project_id).to eq(project.id)
          expect(import_failure.relation_key).to eq('milestones')
          expect(import_failure.relation_index).to be_present
          expect(import_failure.exception_class).to eq('ActiveRecord::RecordInvalid')
          expect(import_failure.exception_message).to be_present
          expect(import_failure.correlation_id_value).not_to be_empty
          expect(import_failure.created_at).to be_present
        end

        context 'when there are a mix of invalid milestones and issues with IIDs' do
          let(:project_fixture) { 'with_invalid_issues_and_milestones' }

          it 'tracks the relation IID if present' do
            iids_for_failures = project.import_failures.collect { |f| [f.relation_key, f.external_identifiers] }
            expected_iids = [
              ["milestones", { "iid" => 1 }],
              ["issues", { "iid" => 9 }],
              ["issues", {}]
            ]

            expect(iids_for_failures).to match_array(expected_iids)
          end
        end
      end
    end

    context 'JSON with design management data' do
      let_it_be(:user) { create(:admin, email: 'user_1@gitlabexample.com') }
      let_it_be(:second_user) { create(:user, email: 'user_2@gitlabexample.com') }
      let_it_be(:project) do
        create(:project, :builds_disabled, :issues_disabled, { name: 'project', path: 'project' })
      end

      let(:shared) { project.import_export_shared }
      let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }

      subject(:restored_project_json) { project_tree_restorer.restore }

      before do
        setup_import_export_config('designs')
        restored_project_json
      end

      it_behaves_like 'restores project successfully', issues: 2

      it 'restores project associations correctly' do
        expect(project.designs.size).to eq(7)
      end

      describe 'restores issue associations correctly' do
        let(:issue) { project.issues.offset(index).first }

        where(:index, :design_filenames, :version_shas, :events, :author_emails) do
          0 | %w[chirrido3.jpg jonathan_richman.jpg mariavontrap.jpeg] | %w[27702d08f5ee021ae938737f84e8fe7c38599e85 9358d1bac8ff300d3d2597adaa2572a20f7f8703 e1a4a501bcb42f291f84e5d04c8f927821542fb6] | %w[creation creation creation modification modification deletion] | %w[user_1@gitlabexample.com user_1@gitlabexample.com user_2@gitlabexample.com]
          1 | ['1 (1).jpeg', '2099743.jpg', 'a screenshot (1).jpg', 'chirrido3.jpg'] | %w[73f871b4c8c1d65c62c460635e023179fb53abc4 8587e78ab6bda3bc820a9f014c3be4a21ad4fcc8 c9b5f067f3e892122a4b12b0a25a8089192f3ac8] | %w[creation creation creation creation modification] | %w[user_1@gitlabexample.com user_2@gitlabexample.com user_2@gitlabexample.com]
        end

        with_them do
          it do
            expect(issue.designs.pluck(:filename)).to contain_exactly(*design_filenames)
            expect(issue.design_versions.pluck(:sha)).to contain_exactly(*version_shas)
            expect(issue.design_versions.flat_map(&:actions).map(&:event)).to contain_exactly(*events)
            expect(issue.design_versions.map(&:author).map(&:email)).to contain_exactly(*author_emails)
          end
        end
      end

      describe 'restores design version associations correctly' do
        let(:project_designs) { project.designs.reorder(:filename, :issue_id) }
        let(:design) { project_designs.offset(index).first }

        where(:index, :version_shas) do
          0 | %w[73f871b4c8c1d65c62c460635e023179fb53abc4 c9b5f067f3e892122a4b12b0a25a8089192f3ac8]
          1 | %w[73f871b4c8c1d65c62c460635e023179fb53abc4]
          2 | %w[c9b5f067f3e892122a4b12b0a25a8089192f3ac8]
          3 | %w[27702d08f5ee021ae938737f84e8fe7c38599e85 9358d1bac8ff300d3d2597adaa2572a20f7f8703 e1a4a501bcb42f291f84e5d04c8f927821542fb6]
          4 | %w[8587e78ab6bda3bc820a9f014c3be4a21ad4fcc8]
          5 | %w[27702d08f5ee021ae938737f84e8fe7c38599e85 e1a4a501bcb42f291f84e5d04c8f927821542fb6]
          6 | %w[27702d08f5ee021ae938737f84e8fe7c38599e85]
        end

        with_them do
          it do
            expect(design.versions.pluck(:sha)).to contain_exactly(*version_shas)
          end
        end
      end
    end
  end

  it_behaves_like 'project tree restorer work properly'
end
