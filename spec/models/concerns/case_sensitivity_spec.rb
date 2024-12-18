# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CaseSensitivity do
  describe '.iwhere' do
    let_it_be(:connection) { Namespace.connection }
    let_it_be(:organization) { create(:organization) }
    let_it_be(:model) do
      Class.new(ActiveRecord::Base) do
        include CaseSensitivity
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled
      end
    end

    let_it_be(:model_1) do
      model.create!(path: 'mOdEl-1', name: 'mOdEl 1', type: Namespaces::UserNamespace.sti_name,
        organization_id: organization.id)
    end

    let_it_be(:model_2) do
      model.create!(path: 'mOdEl-2', name: 'mOdEl 2', type: Group.sti_name, organization_id: organization.id)
    end

    it 'finds a single instance by a single attribute regardless of case' do
      expect(model.iwhere(path: 'MODEL-1')).to contain_exactly(model_1)
    end

    it 'finds multiple instances by a single attribute regardless of case' do
      expect(model.iwhere(path: %w[MODEL-1 model-2])).to contain_exactly(model_1, model_2)
    end

    it 'finds instances by multiple attributes' do
      expect(model.iwhere(path: %w[MODEL-1 model-2], name: 'model 1'))
        .to contain_exactly(model_1)
    end

    it 'finds instances by custom Arel attributes' do
      expect(model.iwhere(model.arel_table[:path] => 'MODEL-1')).to contain_exactly(model_1)
    end

    it 'builds a query using LOWER' do
      query = model.iwhere(path: %w[MODEL-1 model-2], name: 'model 1').to_sql
      expected_query = <<~QRY.strip
      SELECT \"namespaces\".* FROM \"namespaces\" WHERE (LOWER(\"namespaces\".\"path\") IN (LOWER('MODEL-1'), LOWER('model-2'))) AND (LOWER(\"namespaces\".\"name\") = LOWER('model 1'))
      QRY

      expect(query).to eq(expected_query)
    end
  end
end
