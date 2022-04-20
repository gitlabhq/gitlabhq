# frozen_string_literal: true

RSpec.shared_examples 'from set operator' do |sql_klass|
  from_set_operator_concern = described_class
  operator_keyword = sql_klass.operator_keyword
  operator_method = "from_#{sql_klass.operator_keyword.downcase}"

  describe "##{operator_method}" do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'

        include from_set_operator_concern
      end
    end

    it "selects from the results of the #{operator_keyword}" do
      query = model.public_send(operator_method, [model.where(id: 1), model.where(id: 2)])

      expect(query.to_sql).to match(/FROM \(\(SELECT.+\)\n#{operator_keyword}\n\(SELECT.+\)\) users/m)
    end

    it "returns empty set when passing empty array" do
      query = model.public_send(operator_method, [])

      expect(query.to_sql).to match(/WHERE \(1=0\)/m)
    end

    it 'supports the use of a custom alias for the sub query' do
      query = model.public_send(operator_method,
        [model.where(id: 1), model.where(id: 2)],
        alias_as: 'kittens'
      )

      expect(query.to_sql).to match(/FROM \(\(SELECT.+\)\n#{operator_keyword}\n\(SELECT.+\)\) kittens/m)
    end

    it 'supports keeping duplicate rows' do
      query = model.public_send(operator_method,
        [model.where(id: 1), model.where(id: 2)],
        remove_duplicates: false
      )

      expect(query.to_sql)
        .to match(/FROM \(\(SELECT.+\)\n#{operator_keyword} ALL\n\(SELECT.+\)\) users/m)
    end
  end
end
