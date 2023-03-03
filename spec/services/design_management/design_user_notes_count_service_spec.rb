# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::DesignUserNotesCountService, :use_clean_rails_memory_store_caching, feature_category: :design_management do
  let_it_be(:design) { create(:design, :with_file) }

  subject { described_class.new(design) }

  it_behaves_like 'a counter caching service'

  describe '#count' do
    it 'returns the count of notes' do
      create_list(:diff_note_on_design, 3, noteable: design)

      expect(subject.count).to eq(3)
    end
  end

  describe '#cache_key' do
    it 'contains the `VERSION` and `design.id`' do
      expect(subject.cache_key).to eq(['designs', 'notes_count', DesignManagement::DesignUserNotesCountService::VERSION, design.id])
    end
  end

  describe 'cache invalidation' do
    it 'changes when a new note is created' do
      new_note_attrs = attributes_for(:diff_note_on_design, noteable: design)

      expect do
        Notes::CreateService.new(design.project, create(:user), new_note_attrs).execute
      end.to change { subject.count }.by(1)
    end

    it 'changes when a note is destroyed' do
      note = create(:diff_note_on_design, noteable: design)

      expect do
        Notes::DestroyService.new(note.project, note.author).execute(note)
      end.to change { subject.count }.by(-1)
    end
  end
end
