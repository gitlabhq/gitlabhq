# frozen_string_literal: true

require 'spec_helper'

describe FromUnion do
  describe '.from_union' do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'users'

        include FromUnion
      end
    end

    it 'selects from the results of the UNION' do
      query = model.from_union([model.where(id: 1), model.where(id: 2)])

      expect(query.to_sql).to match(/FROM \(SELECT.+UNION.+SELECT.+\) users/m)
    end

    it 'supports the use of a custom alias for the sub query' do
      query = model.from_union(
        [model.where(id: 1), model.where(id: 2)],
        alias_as: 'kittens'
      )

      expect(query.to_sql).to match(/FROM \(SELECT.+UNION.+SELECT.+\) kittens/m)
    end

    it 'supports keeping duplicate rows' do
      query = model.from_union(
        [model.where(id: 1), model.where(id: 2)],
        remove_duplicates: false
      )

      expect(query.to_sql)
        .to match(/FROM \(SELECT.+UNION ALL.+SELECT.+\) users/m)
    end
  end
end
