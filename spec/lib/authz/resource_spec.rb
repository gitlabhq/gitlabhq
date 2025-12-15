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

    let(:resource_name) { 'resource' }
    let(:file_path) { "path/to/config/authz/permissions/#{resource_name}/_metadata.yml" }

    subject(:resource) { described_class.new(definition, file_path) }

    describe '#name' do
      specify do
        expect(resource.name).to eq(resource_name)
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
