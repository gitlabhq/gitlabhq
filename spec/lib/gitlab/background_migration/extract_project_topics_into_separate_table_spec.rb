# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ExtractProjectTopicsIntoSeparateTable,
               :suppress_gitlab_schemas_validate_connection, schema: 20210826171758 do
  it 'correctly extracts project topics into separate table' do
    namespaces = table(:namespaces)
    projects = table(:projects)
    taggings = table(:taggings)
    tags = table(:tags)
    project_topics = table(:project_topics)
    topics = table(:topics)

    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)
    tag_1 = tags.create!(name: 'Topic1')
    tag_2 = tags.create!(name: 'Topic2')
    tag_3 = tags.create!(name: 'Topic3')
    topic_3 = topics.create!(name: 'Topic3')
    tagging_1 = taggings.create!(taggable_type: 'Project', taggable_id: project.id, context: 'topics', tag_id: tag_1.id)
    tagging_2 = taggings.create!(taggable_type: 'Project', taggable_id: project.id, context: 'topics', tag_id: tag_2.id)
    other_tagging = taggings.create!(taggable_type: 'Other', taggable_id: project.id, context: 'topics', tag_id: tag_1.id)
    tagging_3 = taggings.create!(taggable_type: 'Project', taggable_id: project.id, context: 'topics', tag_id: tag_3.id)
    tagging_4 = taggings.create!(taggable_type: 'Project', taggable_id: -1, context: 'topics', tag_id: tag_1.id)
    tagging_5 = taggings.create!(taggable_type: 'Project', taggable_id: project.id, context: 'topics', tag_id: -1)

    subject.perform(tagging_1.id, tagging_5.id)

    # Tagging records
    expect { tagging_1.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { tagging_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { other_tagging.reload }.not_to raise_error
    expect { tagging_3.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { tagging_4.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { tagging_5.reload }.to raise_error(ActiveRecord::RecordNotFound)

    # Topic records
    topic_1 = topics.find_by(name: 'Topic1')
    topic_2 = topics.find_by(name: 'Topic2')
    expect(topics.all).to contain_exactly(topic_1, topic_2, topic_3)

    # ProjectTopic records
    expect(project_topics.all.map(&:topic_id)).to contain_exactly(topic_1.id, topic_2.id, topic_3.id)
  end
end
