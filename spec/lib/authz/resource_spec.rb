# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Resource, feature_category: :permissions do
  it_behaves_like 'loadable from yaml' do
    let(:definition_name) { :job }
  end

  describe 'instance methods' do
    let(:definition) do
      {
        description: 'Description of the resource',
        feature_category: 'feature_category_name'
      }
    end

    let(:resource_dir_name) { 'resource' }
    let(:file_path) { "path/to/config/authz/permissions/#{resource_dir_name}/_metadata.yml" }

    subject(:resource) { described_class.new(definition, file_path) }

    describe '#name' do
      specify do
        expect(resource.name).to eq(resource_dir_name)
      end
    end

    describe '#resource_name' do
      context 'when definition does not have a name value' do
        it 'returns the titlecased parent directory name' do
          expect(resource.resource_name).to eq(resource_dir_name.titlecase)
        end
      end

      context 'when definition has a name value' do
        let(:definition) { super().merge(name: 'Resource Display Name') }

        it 'returns the name from the definition' do
          expect(resource.resource_name).to eq(definition[:name])
        end
      end
    end

    describe '#description' do
      it 'returns the definition description' do
        expect(resource.description).to eq(definition[:description])
      end
    end

    describe '#feature_category' do
      specify do
        expect(resource.feature_category).to eq(definition[:feature_category])
      end
    end
  end
end
