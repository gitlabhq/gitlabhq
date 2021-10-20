# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateTopicsTotalProjectsCountCache, schema: 20211006060436 do
  it 'correctly populates total projects count cache' do
    namespaces = table(:namespaces)
    projects = table(:projects)
    topics = table(:topics)
    project_topics = table(:project_topics)

    group = namespaces.create!(name: 'group', path: 'group')
    project_1 = projects.create!(namespace_id: group.id)
    project_2 = projects.create!(namespace_id: group.id)
    project_3 = projects.create!(namespace_id: group.id)
    topic_1 = topics.create!(name: 'Topic1')
    topic_2 = topics.create!(name: 'Topic2')
    topic_3 = topics.create!(name: 'Topic3')
    topic_4 = topics.create!(name: 'Topic4')

    project_topics.create!(project_id: project_1.id, topic_id: topic_1.id)
    project_topics.create!(project_id: project_1.id, topic_id: topic_3.id)
    project_topics.create!(project_id: project_2.id, topic_id: topic_3.id)
    project_topics.create!(project_id: project_1.id, topic_id: topic_4.id)
    project_topics.create!(project_id: project_2.id, topic_id: topic_4.id)
    project_topics.create!(project_id: project_3.id, topic_id: topic_4.id)

    subject.perform(topic_1.id, topic_4.id)

    expect(topic_1.reload.total_projects_count).to eq(1)
    expect(topic_2.reload.total_projects_count).to eq(0)
    expect(topic_3.reload.total_projects_count).to eq(2)
    expect(topic_4.reload.total_projects_count).to eq(3)
  end
end
