require 'spec_helper'

describe Gitlab::SQL::Union do
  let(:relation_1) { User.where(email: 'alice@example.com').select(:id) }
  let(:relation_2) { User.where(email: 'bob@example.com').select(:id) }

  def to_sql(relation)
    relation.reorder(nil).to_sql
  end

  describe '#to_sql' do
    it 'returns a String joining relations together using a UNION' do
      union = described_class.new([relation_1, relation_2])

      expect(union.to_sql).to eq("#{to_sql(relation_1)}\nUNION\n#{to_sql(relation_2)}")
    end

    it 'skips Model.none segements' do
      empty_relation = User.none
      union = described_class.new([empty_relation, relation_1, relation_2])

      expect {User.where("users.id IN (#{union.to_sql})").to_a}.not_to raise_error
      expect(union.to_sql).to eq("#{to_sql(relation_1)}\nUNION\n#{to_sql(relation_2)}")
    end

    it 'uses UNION ALL when removing duplicates is disabled' do
      union = described_class
        .new([relation_1, relation_2], remove_duplicates: false)

      expect(union.to_sql).to include('UNION ALL')
    end

    it 'returns `NULL` if all relations are empty' do
      empty_relation = User.none
      union = described_class.new([empty_relation, empty_relation])

      expect(union.to_sql).to eq('NULL')
    end
  end
end
