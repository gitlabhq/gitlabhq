# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ProjectEntity, feature_category: :groups_and_projects do
  let(:project) { build_stubbed(:project, name: 'Fooify', path: 'fooify') }
  let(:entity) { described_class.new(project) }

  context 'as json' do
    subject { entity.as_json }

    it 'has releases page as id' do
      expect(subject[:id]).to match(%r{/fooify$})
    end

    it 'is an Application actor' do
      expect(subject[:type]).to eq 'Application'
    end

    it 'provides project name' do
      expect(subject[:name]).to eq project.name
    end

    it 'provides a description of the project' do
      expect(subject[:summary]).to eq project.description
    end

    it 'provides an url for web content' do
      expect(subject[:url]).to match(%r{/fooify$})
    end
  end
end
