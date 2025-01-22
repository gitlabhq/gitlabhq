# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTopicsTitle, schema: 20231220225325 do
  it 'correctly backfills the title of the topics' do
    topics = table(:topics)

    topic_1 = topics.create!(name: 'topic1')
    topic_2 = topics.create!(name: 'topic2', title: 'Topic 2')
    topic_3 = topics.create!(name: 'topic3')
    topic_4 = topics.create!(name: 'topic4')

    subject.perform(topic_1.id, topic_3.id)

    expect(topic_1.reload.title).to eq('topic1')
    expect(topic_2.reload.title).to eq('Topic 2')
    expect(topic_3.reload.title).to eq('topic3')
    expect(topic_4.reload.title).to be_nil
  end
end
