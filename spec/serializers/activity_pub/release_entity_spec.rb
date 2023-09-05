# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ReleaseEntity, feature_category: :groups_and_projects do
  let(:release) { build_stubbed(:release) }
  let(:entity) { described_class.new(release, url: '/outbox') }

  context 'as json' do
    subject { entity.as_json }

    it 'has tag as id' do
      expect(subject[:id]).to match(/##{release.tag}$/)
    end

    it 'is a Create activity' do
      expect(subject[:type]).to eq 'Create'
    end

    it 'is addressed to public' do
      expect(subject[:to]).to eq 'https://www.w3.org/ns/activitystreams#Public'
    end

    it 'has an author' do
      expect(subject[:actor]).to include(:id, :type, :name, :preferredUsername, :url)
    end

    it 'embeds the release as an Application actor' do
      expect(subject[:object][:type]).to eq 'Application'
    end

    it 'provides release name' do
      expect(subject[:object][:name]).to eq release.name
    end

    it 'provides release description' do
      expect(subject[:object][:content]).to eq release.description
    end

    it 'provides an url for web content' do
      expect(subject[:object][:url]).to include release.tag
    end

    it 'provides project data as context' do
      expect(subject[:object][:context]).to include(:id, :type, :name, :summary, :url)
    end
  end
end
