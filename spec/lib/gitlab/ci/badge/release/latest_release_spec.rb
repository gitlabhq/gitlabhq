# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Release::LatestRelease do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_guest(user)
    create(:release, project: project, released_at: 1.day.ago)
  end

  subject { described_class.new(project, user) }

  describe '#entity' do
    it 'describes latest release' do
      expect(subject.entity).to eq 'Latest Release'
    end
  end

  describe '#tag' do
    it 'returns latest release tag for the project ordered using release_at' do
      create(:release, tag: "v1.0.0", project: project, released_at: 1.hour.ago)
      latest_release = create(:release, tag: "v2.0.0", project: project, released_at: Time.current)

      expect(subject.tag).to eq latest_release.tag
    end
  end

  describe '#metadata' do
    it 'returns correct metadata' do
      expect(subject.metadata.image_url).to include 'release.svg'
    end
  end

  describe '#template' do
    it 'returns correct template' do
      expect(subject.template.key_text).to eq 'Latest Release'
    end
  end
end
