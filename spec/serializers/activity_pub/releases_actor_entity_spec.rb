# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ReleasesActorEntity, feature_category: :groups_and_projects do
  let(:project) { build_stubbed(:project, name: 'Fooify', path: 'fooify') }
  let(:releases) { build_stubbed_list(:release, 3, project: project) }

  let(:entity) { described_class.new(project) }

  context 'as json' do
    subject { entity.as_json }

    it 'has releases page as id' do
      expect(subject[:id]).to include "/fooify/-/releases"
    end

    it 'is an Application actor' do
      expect(subject[:type]).to eq 'Application'
    end

    it 'has a recognizable username' do
      expect(subject[:preferredUsername]).to include 'releases'
    end

    it 'has a recognizable full name' do
      expect(subject[:name]).to eq 'Releases - Fooify'
    end

    it 'provides a description of the project' do
      expect(subject[:content]).to eq project.description
    end

    it 'provides project data as context' do
      expect(subject[:context]).to include(:id, :type, :name, :summary, :url)
      expect(subject[:context][:id]).to match(%r{/fooify$})
    end
  end
end
