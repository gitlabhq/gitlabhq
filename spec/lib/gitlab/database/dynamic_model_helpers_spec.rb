# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DynamicModelHelpers do
  let(:including_class) { Class.new.include(described_class) }
  let(:table_name) { 'projects' }

  describe '#define_batchable_model' do
    subject { including_class.new.define_batchable_model(table_name) }

    it 'is an ActiveRecord model' do
      expect(subject.ancestors).to include(ActiveRecord::Base)
    end

    it 'includes EachBatch' do
      expect(subject.included_modules).to include(EachBatch)
    end

    it 'has the correct table name' do
      expect(subject.table_name).to eq(table_name)
    end

    it 'has the inheritance type column disable' do
      expect(subject.inheritance_column).to eq('_type_disabled')
    end
  end

  describe '#each_batch' do
    subject { including_class.new }

    before do
      create_list(:project, 2)
    end

    context 'when no transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(false)
      end

      it 'iterates table in batches' do
        each_batch_size = ->(&block) do
          subject.each_batch(table_name, of: 1) do |batch|
            block.call(batch.size)
          end
        end

        expect { |b| each_batch_size.call(&b) }
          .to yield_successive_args(1, 1)
      end
    end

    context 'when transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(true)
      end

      it 'raises an error' do
        expect { subject.each_batch(table_name, of: 1) { |batch| batch.size } }
          .to raise_error(RuntimeError, /each_batch should not run inside a transaction/)
      end
    end
  end

  describe '#each_batch_range' do
    subject { including_class.new }

    let(:first_project) { create(:project) }
    let(:second_project) { create(:project) }

    context 'when no transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(false)
      end

      it 'iterates table in batch ranges' do
        expect { |b| subject.each_batch_range(table_name, of: 1, &b) }
          .to yield_successive_args(
            [first_project.id, first_project.id],
            [second_project.id, second_project.id]
          )
      end

      it 'yields only one batch if bigger than the table size' do
        expect { |b| subject.each_batch_range(table_name, of: 2, &b) }
          .to yield_successive_args([first_project.id, second_project.id])
      end

      it 'makes it possible to apply a scope' do
        each_batch_limited = ->(&b) do
          subject.each_batch_range(table_name, scope: ->(table) { table.limit(1) }, of: 1, &b)
        end

        expect { |b| each_batch_limited.call(&b) }
          .to yield_successive_args([first_project.id, first_project.id])
      end
    end

    context 'when transaction is open' do
      before do
        allow(subject).to receive(:transaction_open?).and_return(true)
      end

      it 'raises an error' do
        expect { subject.each_batch_range(table_name, of: 1) { 1 } }
          .to raise_error(RuntimeError, /each_batch should not run inside a transaction/)
      end
    end
  end
end
