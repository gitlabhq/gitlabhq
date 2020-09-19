# frozen_string_literal: true

RSpec.shared_examples 'SQL set operator' do |operator_keyword|
  operator_keyword = operator_keyword.upcase

  let(:relation_1) { User.where(email: 'alice@example.com').select(:id) }
  let(:relation_2) { User.where(email: 'bob@example.com').select(:id) }

  def to_sql(relation)
    relation.reorder(nil).to_sql
  end

  describe '.operator_keyword' do
    it { expect(described_class.operator_keyword).to eq operator_keyword }
  end

  describe '#to_sql' do
    it "returns a String joining relations together using a #{operator_keyword}" do
      set_operator = described_class.new([relation_1, relation_2])

      expect(set_operator.to_sql).to eq("(#{to_sql(relation_1)})\n#{operator_keyword}\n(#{to_sql(relation_2)})")
    end

    it 'skips Model.none segements' do
      empty_relation = User.none
      set_operator = described_class.new([empty_relation, relation_1, relation_2])

      expect {User.where("users.id IN (#{set_operator.to_sql})").to_a}.not_to raise_error
      expect(set_operator.to_sql).to eq("(#{to_sql(relation_1)})\n#{operator_keyword}\n(#{to_sql(relation_2)})")
    end

    it "uses #{operator_keyword} ALL when removing duplicates is disabled" do
      set_operator = described_class
        .new([relation_1, relation_2], remove_duplicates: false)

      expect(set_operator.to_sql).to include("#{operator_keyword} ALL")
    end

    it 'returns `NULL` if all relations are empty' do
      empty_relation = User.none
      set_operator = described_class.new([empty_relation, empty_relation])

      expect(set_operator.to_sql).to eq('NULL')
    end
  end
end
