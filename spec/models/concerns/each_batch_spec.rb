require 'spec_helper'

describe EachBatch do
  describe '.each_batch' do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        include EachBatch

        self.table_name = 'users'
      end
    end

    before do
      5.times { create(:user, updated_at: 1.day.ago) }
    end

    it 'yields an ActiveRecord::Relation when a block is given' do
      model.each_batch do |relation|
        expect(relation).to be_a_kind_of(ActiveRecord::Relation)
      end
    end

    it 'yields a batch index as the second argument' do
      model.each_batch do |_, index|
        expect(index).to eq(1)
      end
    end

    it 'accepts a custom batch size' do
      amount = 0

      model.each_batch(of: 1) { amount += 1 }

      expect(amount).to eq(5)
    end

    it 'does not include ORDER BYs in the yielded relations' do
      model.each_batch do |relation|
        expect(relation.to_sql).not_to include('ORDER BY')
      end
    end

    it 'allows updating of the yielded relations' do
      time = Time.now

      model.each_batch do |relation|
        relation.update_all(updated_at: time)
      end

      expect(model.where(updated_at: time).count).to eq(5)
    end
  end
end
