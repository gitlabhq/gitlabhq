# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportCsv::KeysetCollection, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:old_issue) { create(:issue, project: project, created_at: 3.days.ago) }
  let_it_be(:twin_issue_a) { create(:issue, project: project, created_at: 2.days.ago) }
  let_it_be(:twin_issue_b) { create(:issue, project: project, created_at: twin_issue_a.created_at) }
  let_it_be(:new_issue) { create(:issue, project: project, created_at: 1.day.ago) }

  subject(:collection) { described_class.new(project.issues, associations_to_preload: [:author]) }

  def yielded_records
    collection.to_enum(:each).to_a
  end

  describe '#each' do
    it 'yields every record ordered by created_at with id as tie-breaker' do
      expect(yielded_records).to eq([old_issue, twin_issue_a, twin_issue_b, new_issue])
    end

    it 'preloads the given associations' do
      expect(yielded_records).to all(satisfy { |record| record.association(:author).loaded? })
    end

    context 'when the collection spans multiple batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'yields every record exactly once in order' do
        expect(yielded_records).to eq([old_issue, twin_issue_a, twin_issue_b, new_issue])
      end
    end

    context 'with an on_batch_loaded callback' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'invokes the callback once per batch with that batch of records' do
        batches = []
        collection = described_class.new(project.issues, on_batch_loaded: ->(records) { batches << records })

        collection.to_enum(:each).to_a

        expect(batches.size).to eq(2)
        expect(batches.flatten).to eq([old_issue, twin_issue_a, twin_issue_b, new_issue])
      end
    end
  end

  describe '#count' do
    it 'returns the relation count' do
      expect(collection.count).to eq(4)
    end
  end
end
