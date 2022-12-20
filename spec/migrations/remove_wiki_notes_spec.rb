# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveWikiNotes, :migration, feature_category: :team_planning do
  let(:notes) { table(:notes) }

  it 'removes all wiki notes' do
    notes.create!(id: 97, note: 'Wiki note', noteable_type: 'Wiki')
    notes.create!(id: 98, note: 'Commit note', noteable_type: 'Commit')
    notes.create!(id: 110, note: 'Issue note', noteable_type: 'Issue')
    notes.create!(id: 242, note: 'MergeRequest note', noteable_type: 'MergeRequest')

    expect(notes.where(noteable_type: 'Wiki').size).to eq(1)

    expect { migrate! }.to change { notes.count }.by(-1)

    expect(notes.where(noteable_type: 'Wiki').size).to eq(0)
  end

  context 'when not staging nor com' do
    it 'does not remove notes' do
      allow(::Gitlab).to receive(:com?).and_return(false)
      allow(::Gitlab).to receive(:dev_or_test_env?).and_return(false)
      allow(::Gitlab).to receive(:staging?).and_return(false)

      notes.create!(id: 97, note: 'Wiki note', noteable_type: 'Wiki')

      expect { migrate! }.not_to change { notes.count }
    end
  end
end
