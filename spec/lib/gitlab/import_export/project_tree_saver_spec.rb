# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeSaver do
  describe 'saves the project tree into a json object' do
    let(:shared) { project.import_export_shared }
    let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:user) { create(:user) }
    let!(:project) { setup_project }

    before do
      project.add_maintainer(user)
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
      allow_any_instance_of(MergeRequest).to receive(:source_branch_sha).and_return('ABCD')
      allow_any_instance_of(MergeRequest).to receive(:target_branch_sha).and_return('DCBA')
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves project successfully' do
      expect(project_tree_saver.save).to be true
    end

    context ':export_fast_serialize feature flag checks' do
      before do
        expect(Gitlab::ImportExport::Reader).to receive(:new).with(shared: shared).and_return(reader)
        expect(reader).to receive(:project_tree).and_return(project_tree)
      end

      let(:serializer) { instance_double('Gitlab::ImportExport::FastHashSerializer') }
      let(:reader) { instance_double('Gitlab::ImportExport::Reader') }
      let(:project_tree) do
        {
          include: [{ issues: { include: [] } }],
          preload: { issues: nil }
        }
      end

      context 'when :export_fast_serialize feature is enabled' do
        before do
          stub_feature_flags(export_fast_serialize: true)
        end

        it 'uses FastHashSerializer' do
          expect(Gitlab::ImportExport::FastHashSerializer)
            .to receive(:new)
            .with(project, project_tree)
            .and_return(serializer)

          expect(serializer).to receive(:execute)

          project_tree_saver.save
        end
      end

      context 'when :export_fast_serialize feature is disabled' do
        before do
          stub_feature_flags(export_fast_serialize: false)
        end

        it 'is serialized via built-in `as_json`' do
          expect(project).to receive(:as_json).with(project_tree)

          project_tree_saver.save
        end
      end
    end

    # It is mostly duplicated in
    # `spec/lib/gitlab/import_export/fast_hash_serializer_spec.rb`
    # except:
    # context 'with description override' do
    # context 'group members' do
    # ^ These are specific for the ProjectTreeSaver
    context 'JSON' do
      let(:saved_project_json) do
        project_tree_saver.save
        project_json(project_tree_saver.full_path)
      end

      # It is not duplicated in
      # `spec/lib/gitlab/import_export/fast_hash_serializer_spec.rb`
      context 'with description override' do
        let(:params) { { description: 'Foo Bar' } }
        let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared, params: params) }

        it 'overrides the project description' do
          expect(saved_project_json).to include({ 'description' => params[:description] })
        end
      end

      it 'saves the correct json' do
        expect(saved_project_json).to include({ 'description' => 'description', 'visibility_level' => 20 })
      end

      it 'has approvals_before_merge set' do
        expect(saved_project_json['approvals_before_merge']).to eq(1)
      end

      it 'has milestones' do
        expect(saved_project_json['milestones']).not_to be_empty
      end

      it 'has merge requests' do
        expect(saved_project_json['merge_requests']).not_to be_empty
      end

      it 'has merge request\'s milestones' do
        expect(saved_project_json['merge_requests'].first['milestone']).not_to be_empty
      end

      it 'has merge request\'s source branch SHA' do
        expect(saved_project_json['merge_requests'].first['source_branch_sha']).to eq('ABCD')
      end

      it 'has merge request\'s target branch SHA' do
        expect(saved_project_json['merge_requests'].first['target_branch_sha']).to eq('DCBA')
      end

      it 'has events' do
        expect(saved_project_json['merge_requests'].first['milestone']['events']).not_to be_empty
      end

      it 'has snippets' do
        expect(saved_project_json['snippets']).not_to be_empty
      end

      it 'has snippet notes' do
        expect(saved_project_json['snippets'].first['notes']).not_to be_empty
      end

      it 'has releases' do
        expect(saved_project_json['releases']).not_to be_empty
      end

      it 'has no author on releases' do
        expect(saved_project_json['releases'].first['author']).to be_nil
      end

      it 'has the author ID on releases' do
        expect(saved_project_json['releases'].first['author_id']).not_to be_nil
      end

      it 'has issues' do
        expect(saved_project_json['issues']).not_to be_empty
      end

      it 'has issue comments' do
        notes = saved_project_json['issues'].first['notes']

        expect(notes).not_to be_empty
        expect(notes.first['type']).to eq('DiscussionNote')
      end

      it 'has issue assignees' do
        expect(saved_project_json['issues'].first['issue_assignees']).not_to be_empty
      end

      it 'has author on issue comments' do
        expect(saved_project_json['issues'].first['notes'].first['author']).not_to be_empty
      end

      it 'has project members' do
        expect(saved_project_json['project_members']).not_to be_empty
      end

      it 'has merge requests diffs' do
        expect(saved_project_json['merge_requests'].first['merge_request_diff']).not_to be_empty
      end

      it 'has merge request diff files' do
        expect(saved_project_json['merge_requests'].first['merge_request_diff']['merge_request_diff_files']).not_to be_empty
      end

      it 'has merge request diff commits' do
        expect(saved_project_json['merge_requests'].first['merge_request_diff']['merge_request_diff_commits']).not_to be_empty
      end

      it 'has merge requests comments' do
        expect(saved_project_json['merge_requests'].first['notes']).not_to be_empty
      end

      it 'has author on merge requests comments' do
        expect(saved_project_json['merge_requests'].first['notes'].first['author']).not_to be_empty
      end

      it 'has pipeline stages' do
        expect(saved_project_json.dig('ci_pipelines', 0, 'stages')).not_to be_empty
      end

      it 'has pipeline statuses' do
        expect(saved_project_json.dig('ci_pipelines', 0, 'stages', 0, 'statuses')).not_to be_empty
      end

      it 'has pipeline builds' do
        builds_count = saved_project_json
          .dig('ci_pipelines', 0, 'stages', 0, 'statuses')
          .count { |hash| hash['type'] == 'Ci::Build' }

        expect(builds_count).to eq(1)
      end

      it 'has no when YML attributes but only the DB column' do
        expect_any_instance_of(Gitlab::Ci::YamlProcessor).not_to receive(:build_attributes)

        saved_project_json
      end

      it 'has pipeline commits' do
        expect(saved_project_json['ci_pipelines']).not_to be_empty
      end

      it 'has ci pipeline notes' do
        expect(saved_project_json['ci_pipelines'].first['notes']).not_to be_empty
      end

      it 'has labels with no associations' do
        expect(saved_project_json['labels']).not_to be_empty
      end

      it 'has labels associated to records' do
        expect(saved_project_json['issues'].first['label_links'].first['label']).not_to be_empty
      end

      it 'has project and group labels' do
        label_types = saved_project_json['issues'].first['label_links'].map { |link| link['label']['type'] }

        expect(label_types).to match_array(%w(ProjectLabel GroupLabel))
      end

      it 'has priorities associated to labels' do
        priorities = saved_project_json['issues'].first['label_links'].flat_map { |link| link['label']['priorities'] }

        expect(priorities).not_to be_empty
      end

      it 'has issue resource label events' do
        expect(saved_project_json['issues'].first['resource_label_events']).not_to be_empty
      end

      it 'has merge request resource label events' do
        expect(saved_project_json['merge_requests'].first['resource_label_events']).not_to be_empty
      end

      it 'saves the correct service type' do
        expect(saved_project_json['services'].first['type']).to eq('CustomIssueTrackerService')
      end

      it 'saves the properties for a service' do
        expect(saved_project_json['services'].first['properties']).to eq('one' => 'value')
      end

      it 'has project feature' do
        project_feature = saved_project_json['project_feature']
        expect(project_feature).not_to be_empty
        expect(project_feature["issues_access_level"]).to eq(ProjectFeature::DISABLED)
        expect(project_feature["wiki_access_level"]).to eq(ProjectFeature::ENABLED)
        expect(project_feature["builds_access_level"]).to eq(ProjectFeature::PRIVATE)
      end

      it 'has custom attributes' do
        expect(saved_project_json['custom_attributes'].count).to eq(2)
      end

      it 'has badges' do
        expect(saved_project_json['project_badges'].count).to eq(2)
      end

      it 'does not complain about non UTF-8 characters in MR diff files' do
        ActiveRecord::Base.connection.execute("UPDATE merge_request_diff_files SET diff = '---\n- :diff: !binary |-\n    LS0tIC9kZXYvbnVsbAorKysgYi9pbWFnZXMvbnVjb3IucGRmCkBAIC0wLDAg\n    KzEsMTY3OSBAQAorJVBERi0xLjUNJeLjz9MNCisxIDAgb2JqDTw8L01ldGFk\n    YXR'")

        expect(project_tree_saver.save).to be true
      end

      context 'group members' do
        let(:user2) { create(:user, email: 'group@member.com') }
        let(:member_emails) do
          saved_project_json['project_members'].map do |pm|
            pm['user']['email']
          end
        end

        before do
          Group.first.add_developer(user2)
        end

        it 'does not export group members if it has no permission' do
          Group.first.add_developer(user)

          expect(member_emails).not_to include('group@member.com')
        end

        it 'does not export group members as maintainer' do
          Group.first.add_maintainer(user)

          expect(member_emails).not_to include('group@member.com')
        end

        it 'exports group members as group owner' do
          Group.first.add_owner(user)

          expect(member_emails).to include('group@member.com')
        end

        context 'as admin' do
          let(:user) { create(:admin) }

          it 'exports group members as admin' do
            expect(member_emails).to include('group@member.com')
          end

          it 'exports group members as project members' do
            member_types = saved_project_json['project_members'].map { |pm| pm['source_type'] }

            expect(member_types).to all(eq('Project'))
          end
        end
      end

      context 'project attributes' do
        it 'does not contain the runners token' do
          expect(saved_project_json).not_to include("runners_token" => 'token')
        end
      end

      it 'has a board and a list' do
        expect(saved_project_json['boards'].first['lists']).not_to be_empty
      end
    end
  end

  def setup_project
    issue = create(:issue, assignees: [user])
    snippet = create(:project_snippet)
    release = create(:release)
    group = create(:group)

    project = create(:project,
                     :public,
                     :repository,
                     :issues_disabled,
                     :wiki_enabled,
                     :builds_private,
                     description: 'description',
                     issues: [issue],
                     snippets: [snippet],
                     releases: [release],
                     group: group,
                     approvals_before_merge: 1
                    )
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
    create(:discussion_note, noteable: issue, project: project)
    create(:note, noteable: merge_request, project: project)
    create(:note, noteable: snippet, project: project)
    create(:note_on_commit,
           author: user,
           project: project,
           commit_id: ci_build.pipeline.sha)

    create(:resource_label_event, label: project_label, issue: issue)
    create(:resource_label_event, label: group_label, merge_request: merge_request)

    create(:event, :created, target: milestone, project: project, author: user)
    create(:service, project: project, type: 'CustomIssueTrackerService', category: 'issue_tracker', properties: { one: 'value' })

    create(:project_custom_attribute, project: project)
    create(:project_custom_attribute, project: project)

    create(:project_badge, project: project)
    create(:project_badge, project: project)

    board = create(:board, project: project, name: 'TestBoard')
    create(:list, board: board, position: 0, label: project_label)

    project
  end

  def project_json(filename)
    JSON.parse(IO.read(filename))
  end
end
