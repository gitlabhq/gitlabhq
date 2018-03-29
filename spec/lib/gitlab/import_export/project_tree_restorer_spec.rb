require 'spec_helper'
include ImportExport::CommonUtil

describe Gitlab::ImportExport::ProjectTreeRestorer do
  describe 'restore project tree' do
    before(:context) do
      # Using an admin for import, so we can check assignment of existing members
      @user = create(:admin)
      @existing_members = [
        create(:user, username: 'bernard_willms'),
        create(:user, username: 'saul_will')
      ]

      RSpec::Mocks.with_temporary_scope do
        @project = create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project')
        @shared = @project.import_export_shared
        allow(@shared).to receive(:export_path).and_return('spec/lib/gitlab/import_export/')

        allow_any_instance_of(Repository).to receive(:fetch_ref).and_return(true)
        allow_any_instance_of(Gitlab::Git::Repository).to receive(:branch_exists?).and_return(false)

        expect_any_instance_of(Gitlab::Git::Repository).to receive(:create_branch).with('feature', 'DCBA')
        allow_any_instance_of(Gitlab::Git::Repository).to receive(:create_branch)

        project_tree_restorer = described_class.new(user: @user, shared: @shared, project: @project)
        @restored_project_json = project_tree_restorer.restore
      end
    end

    context 'JSON' do
      it 'restores models based on JSON' do
        expect(@restored_project_json).to be_truthy
      end

      it 'restore correct project features' do
        project = Project.find_by_path('project')

        expect(project.project_feature.issues_access_level).to eq(ProjectFeature::DISABLED)
        expect(project.project_feature.builds_access_level).to eq(ProjectFeature::DISABLED)
        expect(project.project_feature.snippets_access_level).to eq(ProjectFeature::ENABLED)
        expect(project.project_feature.wiki_access_level).to eq(ProjectFeature::ENABLED)
        expect(project.project_feature.merge_requests_access_level).to eq(ProjectFeature::ENABLED)
      end

      it 'has the project description' do
        expect(Project.find_by_path('project').description).to eq('Nisi et repellendus ut enim quo accusamus vel magnam.')
      end

      it 'has the project html description' do
        expected_description_html = "<p dir=\"auto\">Nisi et repellendus ut enim quo accusamus vel magnam.</p>"
        expect(Project.find_by_path('project').description_html).to eq(expected_description_html)
      end

      it 'has the same label associated to two issues' do
        expect(ProjectLabel.find_by_title('test2').issues.count).to eq(2)
      end

      it 'has milestones associated to two separate issues' do
        expect(Milestone.find_by_description('test milestone').issues.count).to eq(2)
      end

      it 'creates a valid pipeline note' do
        expect(Ci::Pipeline.first.notes).not_to be_empty
      end

      it 'restores pipelines with missing ref' do
        expect(Ci::Pipeline.where(ref: nil)).not_to be_empty
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
        expect(ProjectLabel.count).to eq(2)
      end

      it 'has no group labels' do
        expect(GroupLabel.count).to eq(0)
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

      it 'restores the correct service' do
        expect(CustomIssueTrackerService.first).not_to be_nil
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
        it 'has a new CI trigger token' do
          expect(Ci::Trigger.where(token: 'cdbfasdf44a5958c83654733449e585')).to be_empty
        end

        it 'has a new CI build token' do
          expect(Ci::Build.where(token: 'abcd')).to be_empty
        end
      end

      context 'has restored the correct number of records' do
        it 'has the correct number of merge requests' do
          expect(@project.merge_requests.size).to eq(9)
        end

        it 'has the correct number of triggers' do
          expect(@project.triggers.size).to eq(1)
        end

        it 'has the correct number of pipelines and statuses' do
          expect(@project.pipelines.size).to eq(5)

          @project.pipelines.zip([2, 2, 2, 2, 2])
            .each do |(pipeline, expected_status_size)|
              expect(pipeline.statuses.size).to eq(expected_status_size)
            end
        end
      end

      context 'when restoring hierarchy of pipeline, stages and jobs' do
        it 'restores pipelines' do
          expect(Ci::Pipeline.all.count).to be 5
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
      end
    end
  end

  shared_examples 'restores project successfully' do
    it 'correctly restores project' do
      expect(shared.errors).to be_empty
      expect(restored_project_json).to be_truthy
    end
  end

  shared_examples 'restores project correctly' do |**results|
    it 'has labels' do
      expect(project.labels.size).to eq(results.fetch(:labels, 0))
    end

    it 'has label priorities' do
      expect(project.labels.first.priorities).not_to be_empty
    end

    it 'has milestones' do
      expect(project.milestones.size).to eq(results.fetch(:milestones, 0))
    end

    it 'has issues' do
      expect(project.issues.size).to eq(results.fetch(:issues, 0))
    end

    it 'has issue with group label and project label' do
      labels = project.issues.first.labels

      expect(labels.where(type: "ProjectLabel").count).to eq(results.fetch(:first_issue_labels, 0))
      expect(labels.where(type: "ProjectLabel").where.not(group_id: nil).count).to eq(0)
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

    it 'has issue with group label' do
      labels = project.issues.first.labels

      expect(labels.where(type: "GroupLabel").count).to eq(results.fetch(:first_issue_labels, 0))
    end
  end

  context 'Light JSON' do
    let(:user) { create(:user) }
    let(:shared) { project.import_export_shared }
    let!(:project) { create(:project, :builds_disabled, :issues_disabled, name: 'project', path: 'project') }
    let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }
    let(:restored_project_json) { project_tree_restorer.restore }

    before do
      allow(shared).to receive(:export_path).and_return('spec/lib/gitlab/import_export/')
    end

    context 'with a simple project' do
      before do
        project_tree_restorer.instance_variable_set(:@path, "spec/lib/gitlab/import_export/project.light.json")

        restored_project_json
      end

      it_behaves_like 'restores project correctly',
                      issues: 1,
                      labels: 1,
                      milestones: 1,
                      first_issue_labels: 1

      context 'project.json file access check' do
        it 'does not read a symlink' do
          Dir.mktmpdir do |tmpdir|
            setup_symlink(tmpdir, 'project.json')
            allow(shared).to receive(:export_path).and_call_original

            restored_project_json

            expect(shared.errors).to be_empty
          end
        end
      end

      context 'when there is an existing build with build token' do
        before do
          create(:ci_build, token: 'abcd')
        end

        it_behaves_like 'restores project successfully'
      end
    end

    context 'when the project has overriden params in import data' do
      it 'overwrites the params stored in the JSON' do
        project.create_import_data(data: { override_params: { description: "Overridden" } })

        restored_project_json

        expect(project.description).to eq("Overridden")
      end

      it 'does not allow setting params that are excluded from import_export settings' do
        project.create_import_data(data: { override_params: { lfs_enabled: true } })

        restored_project_json

        expect(project.lfs_enabled).to be_nil
      end
    end

    context 'with a project that has a group' do
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group))
      end

      before do
        project_tree_restorer.instance_variable_set(:@path, "spec/lib/gitlab/import_export/project.group.json")

        restored_project_json
      end

      it_behaves_like 'restores project successfully'
      it_behaves_like 'restores project correctly',
                      issues: 2,
                      labels: 1,
                      milestones: 1,
                      first_issue_labels: 1

      it_behaves_like 'restores group correctly',
                      labels: 1,
                      milestones: 1,
                      first_issue_labels: 1
    end
  end
end
