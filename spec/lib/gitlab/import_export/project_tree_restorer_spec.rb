require 'spec_helper'
include ImportExport::CommonUtil

describe Gitlab::ImportExport::ProjectTreeRestorer do
  include ImportExport::CommonUtil

  let(:shared) { project.import_export_shared }

  describe 'restore project tree' do
    before(:context) do
      # Using an admin for import, so we can check assignment of existing members
      @user = create(:admin)
      @existing_members = [
        create(:user, username: 'bernard_willms'),
        create(:user, username: 'saul_will')
      ]

      RSpec::Mocks.with_temporary_scope do
        @project = create(:project, :builds_enabled, :issues_disabled, name: 'project', path: 'project')
        @shared = @project.import_export_shared

        setup_import_export_config('complex')

        allow_any_instance_of(Repository).to receive(:fetch_source_branch!).and_return(true)
        allow_any_instance_of(Gitlab::Git::Repository).to receive(:branch_exists?).and_return(false)

        expect_any_instance_of(Gitlab::Git::Repository).to receive(:create_branch).with('feature', 'DCBA')
        allow_any_instance_of(Gitlab::Git::Repository).to receive(:create_branch)

        project_tree_restorer = described_class.new(user: @user, shared: @shared, project: @project)

        expect(Gitlab::ImportExport::RelationFactory).to receive(:create).with(hash_including(excluded_keys: ['whatever'])).and_call_original.at_least(:once)
        allow(project_tree_restorer).to receive(:excluded_keys_for_relation).and_return(['whatever'])

        @restored_project_json = project_tree_restorer.restore
      end
    end

    context 'JSON' do
      before do
        stub_feature_flags(use_legacy_pipeline_triggers: false)
      end

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
            issue_note = Issue.find_by(description: 'Aliquam enim illo et possimus.').notes.select { |n| n.note.match(/#{note_content}/)}.first

            expect(issue_note.note_html).to match(/#{note_content}/)
          end
        end

        context 'for a Merge Request' do
          it 'does not import note_html' do
            note_content = 'Sit voluptatibus eveniet architecto quidem'
            merge_request_note = MergeRequest.find_by(title: 'MR1').notes.select { |n| n.note.match(/#{note_content}/)}.first

            expect(merge_request_note.note_html).to match(/#{note_content}/)
          end
        end
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
      end

      it 'preserves updated_at on issues' do
        issue = Issue.where(description: 'Aliquam enim illo et possimus.').first

        expect(issue.reload.updated_at.to_s).to eq('2016-06-14 15:02:47 UTC')
      end

      it 'has multiple issue assignees' do
        expect(Issue.find_by(title: 'Voluptatem').assignees).to contain_exactly(@user, *@existing_members)
        expect(Issue.find_by(title: 'Issue without assignees').assignees).to be_empty
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

      it 'restores merge requests resource label events' do
        expect(MergeRequest.find_by(title: 'MR1').resource_label_events).not_to be_empty
      end

      it 'restores suggestion' do
        note = Note.find_by("note LIKE 'Saepe asperiores exercitationem non dignissimos laborum reiciendis et ipsum%'")

        expect(note.suggestions.count).to eq(1)
        expect(note.suggestions.first.from_content).to eq("Original line\n")
      end

      context 'event at forth level of the tree' do
        let(:event) { Event.where(action: 6).first }

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

      it 'has the correct data for merge request latest_merge_request_diff' do
        MergeRequest.find_each do |merge_request|
          expect(merge_request.latest_merge_request_diff_id).to eq(merge_request.merge_request_diffs.maximum(:id))
        end
      end

      it 'has labels associated to label links, associated to issues' do
        expect(Label.first.label_links.first.target).not_to be_nil
      end

      it 'has project labels' do
        expect(ProjectLabel.count).to eq(3)
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

        expect(award_emoji.map(&:name)).to contain_exactly('thumbsup', 'coffee')
      end

      it 'restores `ci_cd_settings` : `group_runners_enabled` setting' do
        expect(@project.ci_cd_settings.group_runners_enabled?).to eq(false)
      end

      it 'restores the correct service' do
        expect(CustomIssueTrackerService.first).not_to be_nil
      end

      it 'restores zoom meetings' do
        meetings = @project.issues.first.zoom_meetings

        expect(meetings.count).to eq(1)
        expect(meetings.first.url).to eq('https://zoom.us/j/123456789')
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
      end

      context 'tokens are regenerated' do
        it 'has new CI trigger tokens' do
          expect(Ci::Trigger.where(token: %w[cdbfasdf44a5958c83654733449e585 33a66349b5ad01fc00174af87804e40]))
            .to be_empty
        end

        it 'has a new CI build token' do
          expect(Ci::Build.where(token: 'abcd')).to be_empty
        end
      end

      context 'has restored the correct number of records' do
        it 'has the correct number of merge requests' do
          expect(@project.merge_requests.size).to eq(9)
        end

        it 'only restores valid triggers' do
          expect(@project.triggers.size).to eq(1)
        end

        it 'has the correct number of pipelines and statuses' do
          expect(@project.ci_pipelines.size).to eq(6)

          @project.ci_pipelines.order(:id).zip([2, 2, 2, 2, 2, 0])
            .each do |(pipeline, expected_status_size)|
            expect(pipeline.statuses.size).to eq(expected_status_size)
          end
        end
      end

      context 'when restoring hierarchy of pipeline, stages and jobs' do
        it 'restores pipelines' do
          expect(Ci::Pipeline.all.count).to be 6
        end

        it 'restores pipeline stages' do
          expect(Ci::Stage.all.count).to be 6
        end

        it 'correctly restores association between stage and a pipeline' do
          expect(Ci::Stage.all).to all(have_attributes(pipeline_id: a_value > 0))
        end

        it 'restores statuses' do
          expect(CommitStatus.all.count).to be 10
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

  context 'project.json file access check' do
    let(:user) { create(:user) }
    let!(:project) { create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }
    let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }
    let(:restored_project_json) { project_tree_restorer.restore }

    it 'does not read a symlink' do
      Dir.mktmpdir do |tmpdir|
        setup_symlink(tmpdir, 'project.json')
        allow(shared).to receive(:export_path).and_call_original

        expect(project_tree_restorer.restore).to eq(false)
        expect(shared.errors).to include('Incorrect JSON format')
      end
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
        expect(restored_project_json).to eq(true)
      end

      it_behaves_like 'restores project correctly',
                      issues: 1,
                      labels: 2,
                      label_with_priorities: 'A project label',
                      milestones: 1,
                      first_issue_labels: 1,
                      services: 1

      context 'when there is an existing build with build token' do
        before do
          create(:ci_build, token: 'abcd')
        end

        it_behaves_like 'restores project correctly',
                        issues: 1,
                        labels: 2,
                        label_with_priorities: 'A project label',
                        milestones: 1,
                        first_issue_labels: 1
      end
    end

    context 'when the project has overridden params in import data' do
      before do
        setup_import_export_config('light')
      end

      it 'handles string versions of visibility_level' do
        # Project needs to be in a group for visibility level comparison
        # to happen
        group = create(:group)
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
        project.create_import_data(data: { override_params: { lfs_enabled: true } })

        expect(restored_project_json).to eq(true)
        expect(project.lfs_enabled).to be_falsey
      end

      it 'overrides project feature access levels' do
        access_level_keys = project.project_feature.attributes.keys.select { |a| a =~ /_access_level/ }

        # `pages_access_level` is not included, since it is not available in the public API
        # and has a dependency on project's visibility level
        # see ProjectFeature model
        access_level_keys.delete('pages_access_level')

        disabled_access_levels = Hash[access_level_keys.collect { |item| [item, 'disabled'] }]

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
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE))
      end

      before do
        setup_import_export_config('group')
        expect(restored_project_json).to eq(true)
      end

      it_behaves_like 'restores project correctly',
                      issues: 2,
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
        expect(project.issues.with_state(:opened).count).to eq(1)
      end
    end

    context 'with existing group models' do
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group))
      end

      before do
        setup_import_export_config('light')
      end

      it 'does not import any templated services' do
        expect(restored_project_json).to eq(true)

        expect(project.services.where(template: true).count).to eq(0)
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
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group))
      end

      before do
        setup_import_export_config('milestone-iid')
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
    let(:tree_hash) { { 'visibility_level' => visibility } }
    let(:restorer) { described_class.new(user: nil, shared: shared, project: project) }

    before do
      expect(restorer).to receive(:read_tree_hash) { tree_hash }
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

        project.update(group: group)
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
end
