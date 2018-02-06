require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170927112319_update_notes_type_for_import.rb')

describe UpdateNotesTypeForImport, :migration do
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
      .to contain_exactly('Note', 'Note', 'LegacyDiffNote', 'Github::Import::LegacyDiffNote')
  end
end
