# frozen_string_literal: true

require 'spec_helper'

describe CaseSensitivity do
  describe '.iwhere' do
    let(:connection) { ActiveRecord::Base.connection }
    let(:model) do
      Class.new(ActiveRecord::Base) do
        include CaseSensitivity
        self.table_name = 'namespaces'
      end
    end

    let!(:model_1) { model.create(path: 'mOdEl-1', name: 'mOdEl 1') }
    let!(:model_2) { model.create(path: 'mOdEl-2', name: 'mOdEl 2') }

    it 'finds a single instance by a single attribute regardless of case' do
      expect(model.iwhere(path: 'MODEL-1')).to contain_exactly(model_1)
    end

    it 'finds multiple instances by a single attribute regardless of case' do
      expect(model.iwhere(path: %w(MODEL-1 model-2))).to contain_exactly(model_1, model_2)
    end

    it 'finds instances by multiple attributes' do
      expect(model.iwhere(path: %w(MODEL-1 model-2), name: 'model 1'))
        .to contain_exactly(model_1)
    end

    it 'builds a query using LOWER' do
      query = model.iwhere(path: %w(MODEL-1 model-2), name: 'model 1').to_sql
      expected_query = <<~QRY.strip
      SELECT \"namespaces\".* FROM \"namespaces\" WHERE (LOWER(\"namespaces\".\"path\") IN (LOWER('MODEL-1'), LOWER('model-2'))) AND (LOWER(\"namespaces\".\"name\") = LOWER('model 1'))
      QRY

      expect(query).to eq(expected_query)
    end
  end
end
