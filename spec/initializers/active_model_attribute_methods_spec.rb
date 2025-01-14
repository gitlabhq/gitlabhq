# frozen_string_literal: true

require 'spec_helper'

if ::Gitlab.next_rails?
  RSpec.describe 'ActiveModel::AttributeMethods Patch', feature_category: :database do
    before do
      load Rails.root.join('config/initializers/active_model_attribute_methods.rb')
    end

    describe '.aliases_by_attribute_name' do
      let(:klass) do
        Class.new do
          include ActiveModel::AttributeMethods

          alias_attribute :id_value, :id
          alias_attribute :id_value, :id
        end
      end

      it 'stores the alias attribute only once' do
        expect(klass.aliases_by_attribute_name['id'].to_a).to eq(['id_value'])
      end
    end
  end
end
