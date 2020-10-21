# frozen_string_literal: true

RSpec.shared_examples 'resource mentions migration' do |migration_class, resource_class_name|
  it 'migrates resource mentions' do
    join = migration_class::JOIN
    conditions = migration_class::QUERY_CONDITIONS
    resource_class = "#{Gitlab::BackgroundMigration::UserMentions::Models}::#{resource_class_name}".constantize

    expect do
      subject.perform(resource_class_name, join, conditions, false, resource_class.minimum(:id), resource_class.maximum(:id))
    end.to change { user_mentions.count }.by(1)

    user_mention = user_mentions.last
    expect(user_mention.mentioned_users_ids.sort).to eq(mentioned_users.pluck(:id).sort)
    expect(user_mention.mentioned_groups_ids.sort).to eq([group.id])
    expect(user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)

    # check that performing the same job twice does not fail and does not change counts
    expect do
      subject.perform(resource_class_name, join, conditions, false, resource_class.minimum(:id), resource_class.maximum(:id))
    end.to change { user_mentions.count }.by(0)
  end
end

RSpec.shared_examples 'resource notes mentions migration' do |migration_class, resource_class_name|
  it 'migrates mentions from note' do
    join = migration_class::JOIN
    conditions = migration_class::QUERY_CONDITIONS

    # there are 5 notes for each noteable_type, but two do not have mentions and
    # another one's noteable_id points to an inexistent resource
    expect(notes.where(noteable_type: resource_class_name).count).to eq 5
    expect(user_mentions.count).to eq 0

    expect do
      subject.perform(resource_class_name, join, conditions, true, Note.minimum(:id), Note.maximum(:id))
    end.to change { user_mentions.count }.by(2)

    # check that the user_mention for regular note is created
    user_mention = user_mentions.first
    expect(Note.find(user_mention.note_id).system).to be false
    expect(user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
    expect(user_mention.mentioned_groups_ids.sort).to eq([group.id])
    expect(user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)

    # check that the user_mention for system note is created
    user_mention = user_mentions.second
    expect(Note.find(user_mention.note_id).system).to be true
    expect(user_mention.mentioned_users_ids.sort).to eq(users.pluck(:id).sort)
    expect(user_mention.mentioned_groups_ids.sort).to eq([group.id])
    expect(user_mention.mentioned_groups_ids.sort).not_to include(inaccessible_group.id)

    # check that performing the same job twice does not fail and does not change counts
    expect do
      subject.perform(resource_class_name, join, conditions, true, Note.minimum(:id), Note.maximum(:id))
    end.to change { user_mentions.count }.by(0)
  end
end

RSpec.shared_examples 'schedules resource mentions migration' do |resource_class, is_for_notes|
  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.fake! do
      freeze_time do
        resource_count = is_for_notes ? Note.count : resource_class.count
        expect(resource_count).to eq 5

        migrate!

        migration = described_class::MIGRATION
        join = described_class::JOIN
        conditions = described_class::QUERY_CONDITIONS
        delay = described_class::DELAY

        expect(migration).to be_scheduled_delayed_migration(1 * delay, resource_class.name, join, conditions, is_for_notes, resource1.id, resource1.id)
        expect(migration).to be_scheduled_delayed_migration(2 * delay, resource_class.name, join, conditions, is_for_notes, resource2.id, resource2.id)
        expect(migration).to be_scheduled_delayed_migration(3 * delay, resource_class.name, join, conditions, is_for_notes, resource3.id, resource3.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq 3
      end
    end
  end
end

RSpec.shared_examples 'resource migration not run' do |migration_class, resource_class_name|
  it 'does not migrate mentions' do
    join = migration_class::JOIN
    conditions = migration_class::QUERY_CONDITIONS
    resource_class = "#{Gitlab::BackgroundMigration::UserMentions::Models}::#{resource_class_name}".constantize

    expect do
      subject.perform(resource_class_name, join, conditions, false, resource_class.minimum(:id), resource_class.maximum(:id))
    end.to change { user_mentions.count }.by(0)
  end
end

RSpec.shared_examples 'resource notes migration not run' do |migration_class, resource_class_name|
  it 'does not migrate mentions' do
    join = migration_class::JOIN
    conditions = migration_class::QUERY_CONDITIONS

    expect do
      subject.perform(resource_class_name, join, conditions, true, Note.minimum(:id), Note.maximum(:id))
    end.to change { user_mentions.count }.by(0)
  end
end
