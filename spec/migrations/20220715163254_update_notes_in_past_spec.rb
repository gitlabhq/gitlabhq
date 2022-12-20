# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateNotesInPast, :migration, feature_category: :team_planning do
  let(:notes) { table(:notes) }

  it 'updates created_at when it is too much in the past' do
    notes.create!(id: 10, note: 'note', created_at: '2009-06-01')
    notes.create!(id: 11, note: 'note', created_at: '1970-01-01')
    notes.create!(id: 12, note: 'note', created_at: '1600-06-01')

    migrate!

    expect(notes.all).to contain_exactly(
      an_object_having_attributes(id: 10, created_at: DateTime.parse('2009-06-01')),
      an_object_having_attributes(id: 11, created_at: DateTime.parse('1970-01-01')),
      an_object_having_attributes(id: 12, created_at: DateTime.parse('1970-01-01'))
    )
  end
end
