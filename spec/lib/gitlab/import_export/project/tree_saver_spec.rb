# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::TreeSaver, :with_license, feature_category: :importers do
  let_it_be(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let_it_be(:exportable_path) { 'project' }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:private_project) { create(:project, :private, group: group) }
  let_it_be(:private_mr) { create(:merge_request, source_project: private_project, project: private_project) }
  let_it_be(:project) { setup_project }

  shared_examples 'saves project tree successfully' do
    include ImportExport::CommonUtil

    subject { get_json(full_path, exportable_path, relation_name) }

    describe 'saves project tree attributes' do
      let_it_be(:shared) { project.import_export_shared }

      let(:relation_name) { :projects }

      let_it_be(:full_path) { File.join(shared.export_path, 'tree') }

      before_all do
        RSpec::Mocks.with_temporary_scope do
          stub_all_feature_flags

          project.add_maintainer(user)

          project_tree_saver = described_class.new(project: project, current_user: user, shared: shared)

          project_tree_saver.save # rubocop:disable Rails/SaveBang
        end
      end

      after :all do
        FileUtils.rm_rf(export_path)
      end

      context 'with project root' do
        it do
          is_expected.to include({
            'description' => 'description',
            'visibility_level' => 20,
            'merge_commit_template' => 'merge commit message template',
            'squash_commit_template' => 'squash commit message template'
          })
        end

        it { is_expected.not_to include("runners_token" => 'token') }

        it 'has approvals_before_merge set' do
          expect(subject['approvals_before_merge']).to eq(1)
        end
      end

      context 'with milestones' do
        let(:relation_name) { :milestones }

        it { is_expected.not_to be_empty }
      end

      context 'with merge_requests' do
        let(:relation_name) { :merge_requests }

        it { is_expected.not_to be_empty }

        it 'has merge request\'s milestones' do
          expect(subject.first['milestone']).not_to be_empty
        end

        it 'has merge request\'s source branch SHA' do
          expect(subject.first['source_branch_sha']).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
        end

        it 'has merge request\'s target branch SHA' do
          expect(subject.first['target_branch_sha']).to eq('0b4bc9a49b562e85de7cc9e834518ea6828729b9')
        end

        it 'has events' do
          expect(subject.first['milestone']['events']).not_to be_empty
        end

        it 'has merge requests diffs' do
          expect(subject.first['merge_request_diff']).not_to be_empty
        end

        it 'has merge request diff files' do
          expect(subject.first['merge_request_diff']['merge_request_diff_files']).not_to be_empty
        end

        it 'has merge request diff commits' do
          expect(subject.first['merge_request_diff']['merge_request_diff_commits']).not_to be_empty
        end

        it 'has merge requests comments' do
          expect(subject.first['notes']).not_to be_empty

          diff_note = subject.first['notes'].find { |note| note['type'] == 'DiffNote' }

          expect(diff_note['note_diff_file']['diff_export']).to be_present
        end

        it 'has author on merge requests comments' do
          expect(subject.first['notes'].first['author']).not_to be_empty
        end

        it 'has merge request approvals' do
          approval = subject.first['approvals'].first

          expect(approval).not_to be_nil
          expect(approval['user_id']).to eq(user.id)
        end

        it 'has merge request resource label events' do
          expect(subject.first['resource_label_events']).not_to be_empty
        end

        it 'has merge request assignees' do
          reviewer = subject.first['merge_request_assignees'].first

          expect(reviewer).not_to be_nil
          expect(reviewer['user_id']).to eq(user.id)
        end

        it 'has merge request reviewers' do
          reviewer = subject.first['merge_request_reviewers'].first

          expect(reviewer).not_to be_nil
          expect(reviewer['user_id']).to eq(user.id)
        end

        it 'has merge requests system notes' do
          system_notes = subject.first['notes'].select { |note| note['system'] }

          expect(system_notes.size).to eq(1)
          expect(system_notes.first['note']).to eq('merged')
        end

        it 'has no merge_when_pipeline_succeeds' do
          expect(subject.first['merge_when_pipeline_succeeds']).to be_nil
        end
      end

      context 'with snippets' do
        let(:relation_name) { :snippets }

        it { is_expected.not_to be_empty }

        it 'has snippet notes' do
          expect(subject.first['notes']).not_to be_empty
        end
      end

      context 'with releases' do
        let(:relation_name) { :releases }

        it { is_expected.not_to be_empty }

        it 'has no author on releases' do
          expect(subject.first['author']).to be_nil
        end

        it 'has the author ID on releases' do
          expect(subject.first['author_id']).not_to be_nil
        end
      end

      context 'with issues' do
        let(:relation_name) { :issues }

        it { is_expected.not_to be_empty }

        it 'has a work_item_type' do
          issue = subject.first

          expect(issue['work_item_type']).to eq('base_type' => 'task')
        end

        it 'has issue comments' do
          notes = subject.first['notes']

          expect(notes).not_to be_empty
          expect(notes.first['type']).to eq('DiscussionNote')
        end

        it 'has issue assignees' do
          expect(subject.first['issue_assignees']).not_to be_empty
        end

        it 'has author on issue comments' do
          expect(subject.first['notes'].first['author']).not_to be_empty
        end

        it 'has labels associated to records' do
          expect(subject.first['label_links'].first['label']).not_to be_empty
        end

        it 'has project and group labels' do
          label_types = subject.first['label_links'].map { |link| link['label']['type'] }

          expect(label_types).to match_array(%w[ProjectLabel GroupLabel])
        end

        it 'has priorities associated to labels' do
          priorities = subject.first['label_links'].flat_map { |link| link['label']['priorities'] }

          expect(priorities).not_to be_empty
        end

        it 'has issue resource label events' do
          expect(subject.first['resource_label_events']).not_to be_empty
        end

        it 'saves the issue designs correctly' do
          expect(subject.first['designs'].size).to eq(1)
        end

        it 'saves the issue design notes correctly' do
          expect(subject.first['designs'].first['notes']).not_to be_empty
        end

        it 'saves the issue design versions correctly' do
          issue_json = subject.first
          actions = issue_json['design_versions'].flat_map { |v| v['actions'] }

          expect(issue_json['design_versions'].size).to eq(2)
          issue_json['design_versions'].each do |version|
            expect(version['author_id']).to be_kind_of(Integer)
          end
          expect(actions.size).to eq(2)
          actions.each do |action|
            expect(action['design']).to be_present
          end
        end
      end

      context 'with ci_pipelines' do
        let(:relation_name) { :ci_pipelines }

        it { is_expected.not_to be_empty }

        it 'has pipeline stages' do
          expect(subject.dig(0, 'stages')).not_to be_empty
        end

        it 'has pipeline builds' do
          count = subject.dig(0, 'stages', 0, 'builds').count

          expect(count).to eq(1)
        end

        it 'has pipeline generic_commit_statuses' do
          count = subject.dig(0, 'stages', 0, 'generic_commit_statuses').count

          expect(count).to eq(1)
        end

        it 'has pipeline bridges' do
          count = subject.dig(0, 'stages', 0, 'bridges').count

          expect(count).to eq(1)
        end
      end

      context 'with commit_notes' do
        let(:relation_name) { :commit_notes }

        it { is_expected.not_to be_empty }
      end

      context 'with labels' do
        let(:relation_name) { :labels }

        it { is_expected.not_to be_empty }
      end

      context 'with project_feature' do
        let(:relation_name) { :project_feature }

        it { is_expected.not_to be_empty }

        it 'has project feature' do
          expect(subject["issues_access_level"]).to eq(ProjectFeature::DISABLED)
          expect(subject["wiki_access_level"]).to eq(ProjectFeature::ENABLED)
          expect(subject["builds_access_level"]).to eq(ProjectFeature::PRIVATE)
        end
      end

      context 'with custom_attributes' do
        let(:relation_name) { :custom_attributes }

        it 'has custom attributes' do
          expect(subject.count).to eq(2)
        end
      end

      context 'with badges' do
        let(:relation_name) { :custom_attributes }

        it 'has badges' do
          expect(subject.count).to eq(2)
        end
      end

      context 'with project_members' do
        let(:relation_name) { :project_members }

        it { is_expected.not_to be_empty }
      end

      context 'with boards' do
        let(:relation_name) { :boards }

        it { is_expected.not_to be_empty }
      end

      context 'with pipeline schedules' do
        let(:relation_name) { :pipeline_schedules }

        it 'has owner_id' do
          expect(subject.first['owner_id']).to be_present
        end
      end
    end

    describe '#saves project tree' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }

      let(:project) { setup_project }
      let(:full_path) { File.join(shared.export_path, 'tree') }

      let(:shared) { project.import_export_shared }
      let(:params) { {} }

      let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared, params: params) }

      before do
        project.add_maintainer(user)

        FileUtils.rm_rf(export_path)
      end

      after do
        FileUtils.rm_rf(export_path)
      end

      context 'overrides group members' do
        let(:user2) { create(:user, email: 'group@member.com') }
        let(:relation_name) { :project_members }

        let(:member_emails) do
          emails = subject.map do |pm|
            pm['user']['public_email']
          end
          emails
        end

        before do
          user2.update!(public_email: user2.email)
          group.add_developer(user2)
        end

        context 'when has no permission' do
          before do
            group.add_developer(user)
            project_tree_saver.save # rubocop:disable Rails/SaveBang
          end

          it 'does not export group members' do
            expect(member_emails).not_to include('group@member.com')
          end
        end

        context 'when has permission as maintainer' do
          before do
            group.add_maintainer(user)

            project_tree_saver.save # rubocop:disable Rails/SaveBang
          end

          it 'does not export group members' do
            expect(member_emails).not_to include('group@member.com')
          end
        end

        context 'when has permission as group owner' do
          before do
            group.add_owner(user)

            project_tree_saver.save # rubocop:disable Rails/SaveBang
          end

          it 'exports group members as group owner' do
            expect(member_emails).to include('group@member.com')
          end
        end

        context 'as admin' do
          let(:user) { create(:admin) }

          before do
            project_tree_saver.save # rubocop:disable Rails/SaveBang
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it 'exports group members as admin' do
              expect(member_emails).to include('group@member.com')
            end

            it 'exports group members as project members' do
              member_types = subject.map { |pm| pm['source_type'] }

              expect(member_types).to all(eq('Project'))
            end
          end

          context 'when admin mode is disabled' do
            it 'does not export group members' do
              expect(member_emails).not_to include('group@member.com')
            end
          end
        end
      end

      context 'with description override' do
        let(:params) { { description: 'Foo Bar' } }
        let(:relation_name) { :projects }

        before do
          project_tree_saver.save # rubocop:disable Rails/SaveBang
        end

        it { is_expected.to include({ 'description' => params[:description] }) }
      end

      it 'saves project successfully' do
        expect(project_tree_saver.save).to be true
      end

      it 'does not complain about non UTF-8 characters in MR diff files' do
        MergeRequestDiffFile.connection.execute("UPDATE merge_request_diff_files SET diff = '---\n- :diff: !binary |-\n    LS0tIC9kZXYvbnVsbAorKysgYi9pbWFnZXMvbnVjb3IucGRmCkBAIC0wLDAg\n    KzEsMTY3OSBAQAorJVBERi0xLjUNJeLjz9MNCisxIDAgb2JqDTw8L01ldGFk\n    YXR'")

        expect(project_tree_saver.save).to be true
      end
    end
  end

  it_behaves_like "saves project tree successfully"

  context 'when streaming has to retry', :aggregate_failures do
    let(:shared) { double('shared', export_path: exportable_path) }
    let(:logger) { Gitlab::Export::Logger.build }
    let(:serializer) { double('serializer') }
    let(:error_class) { Net::OpenTimeout }
    let(:info_params) do
      {
        'error.class': error_class,
        project_name: project.name,
        project_id: project.id
      }
    end

    before do
      allow(Gitlab::ImportExport::Json::StreamingSerializer).to receive(:new).and_return(serializer)
    end

    subject(:project_tree_saver) do
      described_class.new(project: project, current_user: user, shared: shared, logger: logger)
    end

    it 'retries and succeeds' do
      call_count = 0
      allow(serializer).to receive(:execute) do
        call_count += 1
        call_count > 1 ? true : raise(error_class, 'execution expired')
      end

      expect(logger).to receive(:info).with(hash_including(info_params)).once

      expect(project_tree_saver.save).to be(true)
    end

    it 'retries and does not succeed' do
      retry_count = 3
      allow(serializer).to receive(:execute).and_raise(error_class, 'execution expired')

      expect(logger).to receive(:info).with(hash_including(info_params)).exactly(retry_count).times
      expect(shared).to receive(:error).with(instance_of(error_class))

      expect(project_tree_saver.save).to be(false)
    end
  end

  # rubocop: disable Metrics/AbcSize
  def setup_project
    release = create(:release)

    project = create(:project,
      :public,
      :repository,
      :issues_disabled,
      :wiki_enabled,
      :builds_private,
      description: 'description',
      releases: [release],
      group: group,
      approvals_before_merge: 1,
      merge_commit_template: 'merge commit message template',
      squash_commit_template: 'squash commit message template')

    issue = create(:issue, :task, assignees: [user], project: project)
    snippet = create(:project_snippet, project: project)
    project_label = create(:label, project: project)
    group_label = create(:group_label, group: group)
    create(:label_link, label: project_label, target: issue)
    create(:label_link, label: group_label, target: issue)
    create(:label_priority, label: group_label, priority: 1)
    milestone = create(:milestone, project: project)
    merge_request = create(:merge_request, source_project: project, milestone: milestone, assignees: [user], reviewers: [user])
    create(:approval, merge_request: merge_request, user: user)
    create(:diff_note_on_merge_request, project: project, author: user, noteable: merge_request)

    ci_build = create(:ci_build, project: project, when: nil)
    ci_build.pipeline.update!(project: project)
    create(:commit_status, project: project, pipeline: ci_build.pipeline)
    create(:generic_commit_status, pipeline: ci_build.pipeline, ci_stage: ci_build.ci_stage, project: project)
    create(:ci_bridge, pipeline: ci_build.pipeline, ci_stage: ci_build.ci_stage, project: project)

    create(:milestone, project: project)
    discussion_note = create(:discussion_note, noteable: issue, project: project)
    mr_note = create(:note, noteable: merge_request, project: project)
    create(:system_note, noteable: merge_request, project: project, author: user, note: 'merged')
    private_system_note = "mentioned in merge request #{private_mr.to_reference(project)}"
    create(:system_note, noteable: merge_request, project: project, author: user, note: private_system_note)
    create(:note, noteable: snippet, project: project)
    create(:note_on_commit,
      author: user,
      project: project,
      commit_id: ci_build.pipeline.sha)

    create(:system_note_metadata, action: 'description', note: discussion_note)
    create(:system_note_metadata, commit_count: 1, action: 'commit', note: mr_note)

    create(:resource_label_event, label: project_label, issue: issue)
    create(:resource_label_event, label: group_label, merge_request: merge_request)

    create(:event, :created, target: milestone, project: project, author: user)

    create(:project_custom_attribute, project: project)
    create(:project_custom_attribute, project: project)

    create(:project_badge, project: project)
    create(:project_badge, project: project)

    board = create(:board, project: project, name: 'TestBoard')
    create(:list, board: board, position: 0, label: project_label)

    design = create(:design, :with_file, versions_count: 2, issue: issue)
    create(:diff_note_on_design, noteable: design, project: project, author: user)
    create(:ci_pipeline_schedule, project: project, owner: user)

    project
  end
  # rubocop: enable Metrics/AbcSize
end
