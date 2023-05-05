# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateTopicsNonPrivateProjectsCount, schema: 20220125122640 do
  it 'correctly populates the non private projects counters' do
    namespaces = table(:namespaces)
    projects = table(:projects)
    topics = table(:topics)
    project_topics = table(:project_topics)

    group = namespaces.create!(name: 'group', path: 'group')
    project_public = projects.create!(namespace_id: group.id, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    project_internal = projects.create!(namespace_id: group.id, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
    project_private = projects.create!(namespace_id: group.id, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    topic_1 = topics.create!(name: 'Topic1')
    topic_2 = topics.create!(name: 'Topic2')
    topic_3 = topics.create!(name: 'Topic3')
    topic_4 = topics.create!(name: 'Topic4')
    topic_5 = topics.create!(name: 'Topic5')
    topic_6 = topics.create!(name: 'Topic6')
    topic_7 = topics.create!(name: 'Topic7')
    topic_8 = topics.create!(name: 'Topic8')

    project_topics.create!(topic_id: topic_1.id, project_id: project_public.id)
    project_topics.create!(topic_id: topic_2.id, project_id: project_internal.id)
    project_topics.create!(topic_id: topic_3.id, project_id: project_private.id)
    project_topics.create!(topic_id: topic_4.id, project_id: project_public.id)
    project_topics.create!(topic_id: topic_4.id, project_id: project_internal.id)
    project_topics.create!(topic_id: topic_5.id, project_id: project_public.id)
    project_topics.create!(topic_id: topic_5.id, project_id: project_private.id)
    project_topics.create!(topic_id: topic_6.id, project_id: project_internal.id)
    project_topics.create!(topic_id: topic_6.id, project_id: project_private.id)
    project_topics.create!(topic_id: topic_7.id, project_id: project_public.id)
    project_topics.create!(topic_id: topic_7.id, project_id: project_internal.id)
    project_topics.create!(topic_id: topic_7.id, project_id: project_private.id)
    project_topics.create!(topic_id: topic_8.id, project_id: project_public.id)

    subject.perform(topic_1.id, topic_7.id)

    expect(topic_1.reload.non_private_projects_count).to eq(1)
    expect(topic_2.reload.non_private_projects_count).to eq(1)
    expect(topic_3.reload.non_private_projects_count).to eq(0)
    expect(topic_4.reload.non_private_projects_count).to eq(2)
    expect(topic_5.reload.non_private_projects_count).to eq(1)
    expect(topic_6.reload.non_private_projects_count).to eq(1)
    expect(topic_7.reload.non_private_projects_count).to eq(2)
    expect(topic_8.reload.non_private_projects_count).to eq(0)
  end
end
