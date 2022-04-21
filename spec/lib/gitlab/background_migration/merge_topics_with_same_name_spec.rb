# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MergeTopicsWithSameName, schema: 20220331133802 do
  def set_avatar(topic_id, avatar)
    topic = ::Projects::Topic.find(topic_id)
    topic.avatar = avatar
    topic.save!
    topic.avatar.absolute_path
  end

  it 'merges project topics with same case insensitive name' do
    namespaces = table(:namespaces)
    projects = table(:projects)
    topics = table(:topics)
    project_topics = table(:project_topics)

    group_1 = namespaces.create!(name: 'space1', type: 'Group', path: 'space1')
    group_2 = namespaces.create!(name: 'space2', type: 'Group', path: 'space2')
    group_3 = namespaces.create!(name: 'space3', type: 'Group', path: 'space3')
    proj_space_1 = namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: group_1.id)
    proj_space_2 = namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: group_2.id)
    proj_space_3 = namespaces.create!(name: 'proj3', path: 'proj3', type: 'Project', parent_id: group_3.id)
    project_1 = projects.create!(namespace_id: group_1.id, project_namespace_id: proj_space_1.id, visibility_level: 20)
    project_2 = projects.create!(namespace_id: group_2.id, project_namespace_id: proj_space_2.id, visibility_level: 10)
    project_3 = projects.create!(namespace_id: group_3.id, project_namespace_id: proj_space_3.id, visibility_level: 0)
    topic_1_keep = topics.create!(
      name: 'topic1',
      title: 'Topic 1',
      description: 'description 1 to keep',
      total_projects_count: 2,
      non_private_projects_count: 2
    )
    topic_1_remove = topics.create!(
      name: 'TOPIC1',
      title: 'Topic 1',
      description: 'description 1 to remove',
      total_projects_count: 2,
      non_private_projects_count: 1
    )
    topic_2_remove = topics.create!(
      name: 'topic2',
      title: 'Topic 2',
      total_projects_count: 0
    )
    topic_2_keep = topics.create!(
      name: 'TOPIC2',
      title: 'Topic 2',
      description: 'description 2 to keep',
      total_projects_count: 1
    )
    topic_3_remove_1 = topics.create!(
      name: 'topic3',
      title: 'Topic 3',
      total_projects_count: 2,
      non_private_projects_count: 1
    )
    topic_3_keep = topics.create!(
      name: 'Topic3',
      title: 'Topic 3',
      total_projects_count: 2,
      non_private_projects_count: 2
    )
    topic_3_remove_2 = topics.create!(
      name: 'TOPIC3',
      title: 'Topic 3',
      description: 'description 3 to keep',
      total_projects_count: 2,
      non_private_projects_count: 1
    )
    topic_4_keep = topics.create!(
      name: 'topic4',
      title: 'Topic 4'
    )

    project_topics_1 = []
    project_topics_3 = []
    project_topics_removed = []

    project_topics_1 << project_topics.create!(topic_id: topic_1_keep.id, project_id: project_1.id)
    project_topics_1 << project_topics.create!(topic_id: topic_1_keep.id, project_id: project_2.id)
    project_topics_removed << project_topics.create!(topic_id: topic_1_remove.id, project_id: project_2.id)
    project_topics_1 << project_topics.create!(topic_id: topic_1_remove.id, project_id: project_3.id)

    project_topics_3 << project_topics.create!(topic_id: topic_3_keep.id, project_id: project_1.id)
    project_topics_3 << project_topics.create!(topic_id: topic_3_keep.id, project_id: project_2.id)
    project_topics_removed << project_topics.create!(topic_id: topic_3_remove_1.id, project_id: project_1.id)
    project_topics_3 << project_topics.create!(topic_id: topic_3_remove_1.id, project_id: project_3.id)
    project_topics_removed << project_topics.create!(topic_id: topic_3_remove_2.id, project_id: project_1.id)
    project_topics_removed << project_topics.create!(topic_id: topic_3_remove_2.id, project_id: project_3.id)

    avatar_paths = {
      topic_1_keep: set_avatar(topic_1_keep.id, fixture_file_upload('spec/fixtures/avatars/avatar1.png')),
      topic_1_remove: set_avatar(topic_1_remove.id, fixture_file_upload('spec/fixtures/avatars/avatar2.png')),
      topic_2_remove: set_avatar(topic_2_remove.id, fixture_file_upload('spec/fixtures/avatars/avatar3.png')),
      topic_3_remove_1: set_avatar(topic_3_remove_1.id, fixture_file_upload('spec/fixtures/avatars/avatar4.png')),
      topic_3_remove_2: set_avatar(topic_3_remove_2.id, fixture_file_upload('spec/fixtures/avatars/avatar5.png'))
    }

    subject.perform(%w[topic1 topic2 topic3 topic4])

    # Topics
    [topic_1_keep, topic_2_keep, topic_3_keep, topic_4_keep].each(&:reload)
    expect(topic_1_keep.name).to eq('topic1')
    expect(topic_1_keep.description).to eq('description 1 to keep')
    expect(topic_1_keep.total_projects_count).to eq(3)
    expect(topic_1_keep.non_private_projects_count).to eq(2)
    expect(topic_2_keep.name).to eq('TOPIC2')
    expect(topic_2_keep.description).to eq('description 2 to keep')
    expect(topic_2_keep.total_projects_count).to eq(0)
    expect(topic_2_keep.non_private_projects_count).to eq(0)
    expect(topic_3_keep.name).to eq('Topic3')
    expect(topic_3_keep.description).to eq('description 3 to keep')
    expect(topic_3_keep.total_projects_count).to eq(3)
    expect(topic_3_keep.non_private_projects_count).to eq(2)
    expect(topic_4_keep.reload.name).to eq('topic4')

    [topic_1_remove, topic_2_remove, topic_3_remove_1, topic_3_remove_2].each do |topic|
      expect { topic.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    # Topic avatars
    expect(topic_1_keep.avatar).to eq('avatar1.png')
    expect(File.exist?(::Projects::Topic.find(topic_1_keep.id).avatar.absolute_path)).to be_truthy
    expect(topic_2_keep.avatar).to eq('avatar3.png')
    expect(File.exist?(::Projects::Topic.find(topic_2_keep.id).avatar.absolute_path)).to be_truthy
    expect(topic_3_keep.avatar).to eq('avatar4.png')
    expect(File.exist?(::Projects::Topic.find(topic_3_keep.id).avatar.absolute_path)).to be_truthy

    [:topic_1_remove, :topic_2_remove, :topic_3_remove_1, :topic_3_remove_2].each do |topic|
      expect(File.exist?(avatar_paths[topic])).to be_falsey
    end

    # Project Topic assignments
    project_topics_1.each do |project_topic|
      expect(project_topic.reload.topic_id).to eq(topic_1_keep.id)
    end

    project_topics_3.each do |project_topic|
      expect(project_topic.reload.topic_id).to eq(topic_3_keep.id)
    end

    project_topics_removed.each do |project_topic|
      expect { project_topic.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
