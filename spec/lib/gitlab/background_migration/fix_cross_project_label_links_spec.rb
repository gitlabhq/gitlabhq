require 'spec_helper'

describe Gitlab::BackgroundMigration::FixCrossProjectLabelLinks, :migration, schema: 20180702120647 do
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:issues_table) { table(:issues) }
  let(:merge_requests_table) { table(:merge_requests) }
  let(:labels_table) { table(:labels) }
  let(:label_links_table) { table(:label_links) }

  let!(:group1) { namespaces_table.create(id: 10, type: 'Group', name: 'group1', path: 'group1') }
  let!(:group2) { namespaces_table.create(id: 20, type: 'Group', name: 'group2', path: 'group2') }

  let!(:project1) { projects_table.create(id: 1, name: 'project1', path: 'group1/project1', namespace_id: 10) }
  let!(:project2) { projects_table.create(id: 3, name: 'project2', path: 'group1/project2', namespace_id: 20) }

  let!(:label1) { labels_table.create(id: 1, title: 'bug', color: 'red', group_id: 10, type: 'GroupLabel') }
  let!(:label2) { labels_table.create(id: 2, title: 'bug', color: 'red', group_id: 20, type: 'GroupLabel') }

  let(:merge_request) do
    merge_requests_table.create(target_project_id: project.id,
                                target_branch: 'master',
                                source_project_id: project.id,
                                source_branch: 'mr name',
                                title: 'mr name')
  end

  it 'updates cross-project label links which exist in the local project or group' do
    issues_table.create(id: 1, title: 'issue1', project_id: 1)
    link = label_links_table.create(label_id: 2, target_type: 'Issue', target_id: 1)

    subject.perform(1, 100)

    expect(link.reload.label_id).to eq(1)
  end

  it 'ignores cross-project label links if label color is different' do
    labels_table.create(id: 3, title: 'bug', color: 'green', group_id: 20, type: 'GroupLabel')
    issues_table.create(id: 1, title: 'issue1', project_id: 1)
    link = label_links_table.create(label_id: 3, target_type: 'Issue', target_id: 1)

    subject.perform(1, 100)

    expect(link.reload.label_id).to eq(3)
  end

  it 'ignores cross-project label links if label name is different' do
    labels_table.create(id: 3, title: 'bug1', color: 'red', group_id: 20, type: 'GroupLabel')
    issues_table.create(id: 1, title: 'issue1', project_id: 1)
    link = label_links_table.create(label_id: 3, target_type: 'Issue', target_id: 1)

    subject.perform(1, 100)

    expect(link.reload.label_id).to eq(3)
  end

  context 'with nested group' do
    before do
      namespaces_table.create(id: 11, type: 'Group', name: 'subgroup1', path: 'group1/subgroup1', parent_id: 10)
      projects_table.create(id: 2, name: 'subproject1', path: 'group1/subgroup1/subproject1', namespace_id: 11)
      issues_table.create(id: 1, title: 'issue1', project_id: 2)
    end

    it 'ignores label links referencing ancestor group labels', :nested_groups do
      labels_table.create(id: 4, title: 'bug', color: 'red', project_id: 2, type: 'ProjectLabel')
      label_links_table.create(label_id: 4, target_type: 'Issue', target_id: 1)
      link = label_links_table.create(label_id: 1, target_type: 'Issue', target_id: 1)

      subject.perform(1, 100)

      expect(link.reload.label_id).to eq(1)
    end

    it 'checks also issues and MRs in subgroups', :nested_groups do
      link = label_links_table.create(label_id: 2, target_type: 'Issue', target_id: 1)

      subject.perform(1, 100)

      expect(link.reload.label_id).to eq(1)
    end
  end
end
