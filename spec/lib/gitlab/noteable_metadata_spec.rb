# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::NoteableMetadata do
  subject { Class.new { include Gitlab::NoteableMetadata }.new }

  it 'returns an empty Hash if an empty collection is provided' do
    expect(subject.noteable_meta_data(Snippet.none, 'Snippet')).to eq({})
  end

  it 'raises an error when given a collection with no limit' do
    expect { subject.noteable_meta_data(Snippet.all, 'Snippet') }.to raise_error(/must have a limit/)
  end

  context 'snippets' do
    let!(:snippet) { create(:personal_snippet) }
    let!(:other_snippet) { create(:personal_snippet) }
    let!(:note) { create(:note, noteable: snippet) }

    it 'aggregates stats on snippets' do
      data = subject.noteable_meta_data(Snippet.all.limit(10), 'Snippet')

      expect(data.count).to eq(2)
      expect(data[snippet.id].user_notes_count).to eq(1)
      expect(data[other_snippet.id].user_notes_count).to eq(0)
    end
  end
end
