# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BulkInsertableTags do
  let(:taggable_class) do
    Class.new do
      prepend Ci::BulkInsertableTags

      attr_reader :tags_saved

      def save_tags
        @tags_saved = true
      end
    end
  end

  let(:record) { taggable_class.new }

  describe '.with_bulk_insert_tags' do
    it 'changes the thread key to true' do
      expect(Thread.current['ci_bulk_insert_tags']).to be_nil

      described_class.with_bulk_insert_tags do
        expect(Thread.current['ci_bulk_insert_tags']).to eq(true)
      end

      expect(Thread.current['ci_bulk_insert_tags']).to be_nil
    end
  end

  describe '#save_tags' do
    it 'calls super' do
      record.save_tags

      expect(record.tags_saved).to eq(true)
    end

    it 'does not call super with BulkInsertableTags.with_bulk_insert_tags' do
      described_class.with_bulk_insert_tags do
        record.save_tags
      end

      expect(record.tags_saved).to be_nil
    end

    it 'isolates bulk insert behavior between threads' do
      record2 = taggable_class.new

      t1 = Thread.new do
        described_class.with_bulk_insert_tags do
          record.save_tags
        end
      end

      t2 = Thread.new do
        record2.save_tags
      end

      [t1, t2].each(&:join)

      expect(record.tags_saved).to be_nil
      expect(record2.tags_saved).to eq(true)
    end
  end
end
