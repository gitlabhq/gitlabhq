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

    it 'skips Model.none segments' do
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

  describe 'remove_order parameter' do
    let(:scopes) do
      [
        User.where(id: 1).order(id: :desc).limit(1),
        User.where(id: 2).order(id: :asc).limit(1)
      ]
    end

    subject(:union_query) { described_class.new(scopes, remove_order: remove_order).to_sql }

    context 'when remove_order: true' do
      let(:remove_order) { true }

      it 'removes the ORDER BY from the query' do
        expect(union_query).not_to include('ORDER BY "users"."id" DESC')
        expect(union_query).not_to include('ORDER BY "users"."id" ASC')
      end
    end

    context 'when remove_order: false' do
      let(:remove_order) { false }

      it 'does not remove the ORDER BY from the query' do
        expect(union_query).to include('ORDER BY "users"."id" DESC')
        expect(union_query).to include('ORDER BY "users"."id" ASC')
      end
    end
  end
end
