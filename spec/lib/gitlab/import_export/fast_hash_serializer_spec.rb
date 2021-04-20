# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::FastHashSerializer do
  # FastHashSerializer#execute generates the hash which is not easily accessible
  # and includes `JSONBatchRelation` items which are serialized at this point.
  # Wrapping the result into JSON generating/parsing is for making
  # the testing more convenient. Doing this, we can check that
  # all items are properly serialized while traversing the simple hash.
  subject { Gitlab::Json.parse(Gitlab::Json.generate(described_class.new(project, tree).execute)) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { setup_project }

  let(:shared) { project.import_export_shared }
  let(:reader) { Gitlab::ImportExport::Reader.new(shared: shared) }
  let(:tree) { reader.project_tree }

  before_all do
    project.add_maintainer(user)
  end

  before do
    allow_any_instance_of(MergeRequest).to receive(:source_branch_sha).and_return('ABCD')
    allow_any_instance_of(MergeRequest).to receive(:target_branch_sha).and_return('DCBA')
  end

  it 'saves the correct hash' do
    is_expected.to include({ 'description' => 'description', 'visibility_level' => 20 })
  end

  it 'has approvals_before_merge set' do
    expect(subject['approvals_before_merge']).to eq(1)
  end

  it 'has milestones' do
    expect(subject['milestones']).not_to be_empty
  end

  it 'has merge requests' do
    expect(subject['merge_requests']).not_to be_empty
  end

  it 'has merge request\'s milestones' do
    expect(subject['merge_requests'].first['milestone']).not_to be_empty
  end

  it 'has merge request\'s source branch SHA' do
    expect(subject['merge_requests'].first['source_branch_sha']).to eq('ABCD')
  end

  it 'has merge request\'s target branch SHA' do
    expect(subject['merge_requests'].first['target_branch_sha']).to eq('DCBA')
  end

  it 'has events' do
    expect(subject['merge_requests'].first['milestone']['events']).not_to be_empty
  end

  it 'has snippets' do
    expect(subject['snippets']).not_to be_empty
  end

  it 'has snippet notes' do
    expect(subject['snippets'].first['notes']).not_to be_empty
  end

  it 'has releases' do
    expect(subject['releases']).not_to be_empty
  end

  it 'has no author on releases' do
    expect(subject['releases'].first['author']).to be_nil
  end

  it 'has the author ID on releases' do
    expect(subject['releases'].first['author_id']).not_to be_nil
  end

  it 'has issues' do
    expect(subject['issues']).not_to be_empty
  end

  it 'has issue comments' do
    notes = subject['issues'].first['notes']

    expect(notes).not_to be_empty
    expect(notes.first['type']).to eq('DiscussionNote')
  end

  it 'has issue assignees' do
    expect(subject['issues'].first['issue_assignees']).not_to be_empty
  end

  it 'has author on issue comments' do
    expect(subject['issues'].first['notes'].first['author']).not_to be_empty
  end

  it 'has project members' do
    expect(subject['project_members']).not_to be_empty
  end

  it 'has merge requests diffs' do
    expect(subject['merge_requests'].first['merge_request_diff']).not_to be_empty
  end

  it 'has merge request diff files' do
    expect(subject['merge_requests'].first['merge_request_diff']['merge_request_diff_files']).not_to be_empty
  end

  it 'has merge request diff commits' do
    expect(subject['merge_requests'].first['merge_request_diff']['merge_request_diff_commits']).not_to be_empty
  end

  it 'has merge requests comments' do
    expect(subject['merge_requests'].first['notes']).not_to be_empty
  end

  it 'has author on merge requests comments' do
    expect(subject['merge_requests'].first['notes'].first['author']).not_to be_empty
  end

  it 'has pipeline stages' do
    expect(subject.dig('ci_pipelines', 0, 'stages')).not_to be_empty
  end

  it 'has pipeline statuses' do
    expect(subject.dig('ci_pipelines', 0, 'stages', 0, 'statuses')).not_to be_empty
  end

  it 'has pipeline builds' do
    builds_count = subject
      .dig('ci_pipelines', 0, 'stages', 0, 'statuses')
      .count { |hash| hash['type'] == 'Ci::Build' }

    expect(builds_count).to eq(1)
  end

  it 'has pipeline commits' do
    expect(subject['ci_pipelines']).not_to be_empty
  end

  it 'has ci pipeline notes' do
    expect(subject['ci_pipelines'].first['notes']).not_to be_empty
  end

  it 'has labels with no associations' do
    expect(subject['labels']).not_to be_empty
  end

  it 'has labels associated to records' do
    expect(subject['issues'].first['label_links'].first['label']).not_to be_empty
  end

  it 'has project and group labels' do
    label_types = subject['issues'].first['label_links'].map { |link| link['label']['type'] }

    expect(label_types).to match_array(%w(ProjectLabel GroupLabel))
  end

  it 'has priorities associated to labels' do
    priorities = subject['issues'].first['label_links'].flat_map { |link| link['label']['priorities'] }

    expect(priorities).not_to be_empty
  end

  it 'has issue resource label events' do
    expect(subject['issues'].first['resource_label_events']).not_to be_empty
  end

  it 'has merge request resource label events' do
    expect(subject['merge_requests'].first['resource_label_events']).not_to be_empty
  end

  it 'has project feature' do
    project_feature = subject['project_feature']
    expect(project_feature).not_to be_empty
    expect(project_feature["issues_access_level"]).to eq(ProjectFeature::DISABLED)
    expect(project_feature["wiki_access_level"]).to eq(ProjectFeature::ENABLED)
    expect(project_feature["builds_access_level"]).to eq(ProjectFeature::PRIVATE)
  end

  it 'has custom attributes' do
    expect(subject['custom_attributes'].count).to eq(2)
  end

  it 'has badges' do
    expect(subject['project_badges'].count).to eq(2)
  end

  it 'does not complain about non UTF-8 characters in MR diff files' do
    ActiveRecord::Base.connection.execute("UPDATE merge_request_diff_files SET diff = '---\n- :diff: !binary |-\n    LS0tIC9kZXYvbnVsbAorKysgYi9pbWFnZXMvbnVjb3IucGRmCkBAIC0wLDAg\n    KzEsMTY3OSBAQAorJVBERi0xLjUNJeLjz9MNCisxIDAgb2JqDTw8L01ldGFk\n    YXR'")

    expect(subject['merge_requests'].first['merge_request_diff']).not_to be_empty
  end

  context 'project attributes' do
    it 'does not contain the runners token' do
      expect(subject).not_to include("runners_token" => 'token')
    end
  end

  it 'has a board and a list' do
    expect(subject['boards'].first['lists']).not_to be_empty
  end

  context 'relation ordering' do
    it 'orders exported pipelines by primary key' do
      expected_order = project.ci_pipelines.reorder(:id).ids

      expect(subject['ci_pipelines'].pluck('id')).to eq(expected_order)
    end
  end

  def setup_project
    release = create(:release)
    group = create(:group)

    project = create(:project,
                     :public,
                     :repository,
                     :issues_disabled,
                     :wiki_enabled,
                     :builds_private,
                     description: 'description',
                     releases: [release],
                     group: group,
                     approvals_before_merge: 1
                    )

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

    create_list(:ci_pipeline, 5, :success, project: project)

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
end
