require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170927112318_update_legacy_diff_notes_type_for_import.rb')

describe UpdateLegacyDiffNotesTypeForImport, :migration do
  let(:notes) { table(:notes) }

  before do
    notes.inheritance_column = nil

    notes.create(type: 'Note')
    notes.create(type: 'LegacyDiffNote')
    notes.create(type: 'Github::Import::Note')
    notes.create(type: 'Github::Import::LegacyDiffNote')
  end

  it 'updates the notes type' do
    migrate!

    expect(notes.pluck(:type))
      .to contain_exactly('Note', 'Github::Import::Note', 'LegacyDiffNote', 'LegacyDiffNote')
  end
end
