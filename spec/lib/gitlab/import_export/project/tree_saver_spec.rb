# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::TreeSaver do
  let_it_be(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let_it_be(:exportable_path) { 'project' }

  shared_examples 'saves project tree successfully' do |ndjson_enabled|
    include ImportExport::CommonUtil

    subject { get_json(full_path, exportable_path, relation_name, ndjson_enabled) }

    describe 'saves project tree attributes' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { setup_project }
      let_it_be(:shared) { project.import_export_shared }

      let(:relation_name) { :projects }

      let_it_be(:full_path) do
        if ndjson_enabled
          File.join(shared.export_path, 'tree')
        else
          File.join(shared.export_path, Gitlab::ImportExport.project_filename)
        end
      end

      before_all do
        RSpec::Mocks.with_temporary_scope do
          stub_all_feature_flags
          stub_feature_flags(project_export_as_ndjson: ndjson_enabled)

          project.add_maintainer(user)

          project_tree_saver = described_class.new(project: project, current_user: user, shared: shared)

          project_tree_saver.save
        end
      end

      after :all do
        FileUtils.rm_rf(export_path)
      end

      context 'with project root' do
        it { is_expected.to include({ 'description' => 'description', 'visibility_level' => 20 }) }

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
        end

        it 'has author on merge requests comments' do
          expect(subject.first['notes'].first['author']).not_to be_empty
        end

        it 'has merge request resource label events' do
          expect(subject.first['resource_label_events']).not_to be_empty
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

          expect(label_types).to match_array(%w(ProjectLabel GroupLabel))
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

        it 'has pipeline statuses' do
          expect(subject.dig(0, 'stages', 0, 'statuses')).not_to be_empty
        end

        it 'has pipeline builds' do
          builds_count = subject.dig(0, 'stages', 0, 'statuses')
                           .count { |hash| hash['type'] == 'Ci::Build' }

          expect(builds_count).to eq(1)
        end

        it 'has ci pipeline notes' do
          expect(subject.first['notes']).not_to be_empty
        end
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
    end

    describe '#saves project tree' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }

      let(:project) { setup_project }
      let(:full_path) do
        if ndjson_enabled
          File.join(shared.export_path, 'tree')
        else
          File.join(shared.export_path, Gitlab::ImportExport.project_filename)
        end
      end

      let(:shared) { project.import_export_shared }
      let(:params) { {} }

      let(:project_tree_saver ) { described_class.new(project: project, current_user: user, shared: shared, params: params) }

      before do
        stub_feature_flags(project_export_as_ndjson: ndjson_enabled)
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
            pm['user']['email']
          end
          emails
        end

        before do
          group.add_developer(user2)
        end

        context 'when has no permission' do
          before do
            group.add_developer(user)
            project_tree_saver.save
          end

          it 'does not export group members' do
            expect(member_emails).not_to include('group@member.com')
          end
        end

        context 'when has permission as maintainer' do
          before do
            group.add_maintainer(user)

            project_tree_saver.save
          end

          it 'does not export group members' do
            expect(member_emails).not_to include('group@member.com')
          end
        end

        context 'when has permission as group owner' do
          before do
            group.add_owner(user)

            project_tree_saver.save
          end

          it 'exports group members as group owner' do
            expect(member_emails).to include('group@member.com')
          end
        end

        context 'as admin' do
          let(:user) { create(:admin) }

          before do
            project_tree_saver.save
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
          project_tree_saver.save
        end

        it { is_expected.to include({ 'description' => params[:description] }) }
      end

      it 'saves project successfully' do
        expect(project_tree_saver.save).to be true
      end

      it 'does not complain about non UTF-8 characters in MR diff files' do
        ActiveRecord::Base.connection.execute("UPDATE merge_request_diff_files SET diff = '---\n- :diff: !binary |-\n    LS0tIC9kZXYvbnVsbAorKysgYi9pbWFnZXMvbnVjb3IucGRmCkBAIC0wLDAg\n    KzEsMTY3OSBAQAorJVBERi0xLjUNJeLjz9MNCisxIDAgb2JqDTw8L01ldGFk\n    YXR'")

        expect(project_tree_saver.save).to be true
      end
    end
  end

  context 'with JSON' do
    it_behaves_like "saves project tree successfully", false
  end

  context 'with NDJSON' do
    it_behaves_like "saves project tree successfully", true
  end

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
      approvals_before_merge: 1)

    issue = create(:issue, assignees: [user], project: project)
    snippet = create(:project_snippet, project: project)
    project_label = create(:label, project: project)
    group_label = create(:group_label, group: group)
    create(:label_link, label: project_label, target: issue)
    create(:label_link, label: group_label, target: issue)
    create(:label_priority, label: group_label, priority: 1)
    milestone = create(:milestone, project: project)
    merge_request = create(:merge_request, source_project: project, milestone: milestone)

    ci_build = create(:ci_build, project: project, when: nil)
    ci_build.pipeline.update(project: project)
    create(:commit_status, project: project, pipeline: ci_build.pipeline)

    create(:milestone, project: project)
    discussion_note = create(:discussion_note, noteable: issue, project: project)
    mr_note = create(:note, noteable: merge_request, project: project)
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

    project
  end
end
