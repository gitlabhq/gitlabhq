# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe FinalizeBackfillNullNoteDiscussionIds, :migration, feature_category: :team_planning do
  subject(:migration) { described_class.new }

  let(:notes) { table(:notes) }
  let(:bg_migration_class) { Gitlab::BackgroundMigration::BackfillNoteDiscussionId }
  let(:bg_migration) { instance_double(bg_migration_class) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'performs remaining background migrations', :aggregate_failures do
    # Already migrated
    notes.create!(noteable_type: 'Issue', noteable_id: 1, discussion_id: Digest::SHA1.hexdigest('note1'))
    notes.create!(noteable_type: 'Issue', noteable_id: 1, discussion_id: Digest::SHA1.hexdigest('note2'))
    # update required
    record1 = notes.create!(noteable_type: 'Issue', noteable_id: 1, discussion_id: nil)
    record2 = notes.create!(noteable_type: 'Issue', noteable_id: 1, discussion_id: nil)
    record3 = notes.create!(noteable_type: 'Issue', noteable_id: 1, discussion_id: nil)

    expect(Gitlab::BackgroundMigration).to receive(:steal).with(bg_migration_class.name.demodulize)
    expect(bg_migration_class).to receive(:new).twice.and_return(bg_migration)
    expect(bg_migration).to receive(:perform).with(record1.id, record2.id)
    expect(bg_migration).to receive(:perform).with(record3.id, record3.id)

    migrate!
  end
end
