# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateProjectTaggingsContextFromTagsToTopics, schema: 20210511095658 do
  it 'correctly migrates project taggings context from tags to topics' do
    taggings = table(:taggings)

    project_old_tagging_1 = taggings.create!(taggable_type: 'Project', context: 'tags')
    project_new_tagging_1 = taggings.create!(taggable_type: 'Project', context: 'topics')
    project_other_context_tagging_1 = taggings.create!(taggable_type: 'Project', context: 'other')
    project_old_tagging_2 = taggings.create!(taggable_type: 'Project', context: 'tags')
    project_old_tagging_3 = taggings.create!(taggable_type: 'Project', context: 'tags')

    subject.perform(project_old_tagging_1.id, project_old_tagging_2.id)

    project_old_tagging_1.reload
    project_new_tagging_1.reload
    project_other_context_tagging_1.reload
    project_old_tagging_2.reload
    project_old_tagging_3.reload

    expect(project_old_tagging_1.context).to eq('topics')
    expect(project_new_tagging_1.context).to eq('topics')
    expect(project_other_context_tagging_1.context).to eq('other')
    expect(project_old_tagging_2.context).to eq('topics')
    expect(project_old_tagging_3.context).to eq('tags')
  end
end
