# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EachBatch do
  describe '.each_batch' do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        include EachBatch

        self.table_name = 'users'

        scope :never_signed_in, -> { where(sign_in_count: 0) }
      end
    end

    before do
      create_list(:user, 5, updated_at: 1.day.ago)
    end

    shared_examples 'each_batch handling' do |kwargs|
      it 'yields an ActiveRecord::Relation when a block is given' do
        model.each_batch(**kwargs) do |relation|
          expect(relation).to be_a_kind_of(ActiveRecord::Relation)
        end
      end

      it 'yields a batch index as the second argument' do
        model.each_batch(**kwargs) do |_, index|
          expect(index).to eq(1)
        end
      end

      it 'accepts a custom batch size' do
        amount = 0

        model.each_batch(**kwargs.merge({ of: 1 })) { amount += 1 }

        expect(amount).to eq(5)
      end

      it 'does not include ORDER BYs in the yielded relations' do
        model.each_batch do |relation|
          expect(relation.to_sql).not_to include('ORDER BY')
        end
      end

      it 'allows updating of the yielded relations' do
        time = Time.current

        model.each_batch do |relation|
          relation.update_all(updated_at: time)
        end

        expect(model.where(updated_at: time).count).to eq(5)
      end
    end

    it_behaves_like 'each_batch handling', {}
    it_behaves_like 'each_batch handling', { order_hint: :updated_at }

    it 'orders ascending by default' do
      ids = []

      model.each_batch(of: 1) { |rel| ids.concat(rel.ids) }

      expect(ids).to eq(ids.sort)
    end

    it 'accepts descending order' do
      ids = []

      model.each_batch(of: 1, order: :desc) { |rel| ids.concat(rel.ids) }

      expect(ids).to eq(ids.sort.reverse)
    end

    describe 'current scope' do
      let(:entry) { create(:user, sign_in_count: 1) }
      let(:ids_with_new_relation) { model.where(id: entry.id).pluck(:id) }

      it 'does not leak current scope to block being executed' do
        model.never_signed_in.each_batch(of: 5) do |relation|
          expect(ids_with_new_relation).to include(entry.id)
        end
      end
    end
  end
end
