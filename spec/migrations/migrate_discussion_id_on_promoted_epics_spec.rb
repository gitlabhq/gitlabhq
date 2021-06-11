# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateDiscussionIdOnPromotedEpics do
  let(:migration_class) { described_class::MIGRATION }
  let(:migration_name)  { migration_class.to_s.demodulize }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:issues) { table(:issues) }
  let(:epics) { table(:epics) }
  let(:notes) { table(:notes) }
  let(:system_note_metadata) { table(:system_note_metadata) }

  let(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }

  def create_promotion_note(model, id)
    note = create_note(model, id, { system: true,
                                    note: 'promoted from issue XXX' })
    system_note_metadata.create!(note_id: note.id, action: 'moved')
  end

  def create_epic
    epics.create!(author_id: user.id, iid: epics.maximum(:iid).to_i + 1,
                  group_id: namespace.id,
                  title: 'Epic with discussion',
                  title_html: 'Epic with discussion')
  end

  def create_note(model, id, extra_params = {})
    params = {
      note: 'note',
      noteable_id: model.id,
      noteable_type: model.class.name,
      discussion_id: id
    }.merge(extra_params)

    notes.create!(params)
  end

  context 'with promoted epic' do
    let(:epic1) { create_epic }
    let!(:note1) { create_promotion_note(epic1, 'id1') }

    it 'correctly schedules background migrations in batches' do
      create_note(epic1, 'id2')
      create_note(epic1, 'id3')

      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(migration_name).to be_scheduled_delayed_migration(2.minutes, %w(id1 id2))
          expect(migration_name).to be_scheduled_delayed_migration(4.minutes, %w(id3))
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end

    it 'schedules only promoted epics' do
      issue = issues.create!(description: 'first', state: 'opened')
      create_promotion_note(issue, 'id2')
      create_note(create_epic, 'id3')

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(migration_name).to be_scheduled_delayed_migration(2.minutes, %w(id1))
          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
        end
      end
    end
  end
end
