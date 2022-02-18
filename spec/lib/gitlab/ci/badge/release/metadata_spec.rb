# frozen_string_literal: true

require 'spec_helper'
require 'lib/gitlab/ci/badge/shared/metadata'

RSpec.describe Gitlab::Ci::Badge::Release::Metadata do
  let(:project) { create(:project) }
  let(:ref) { 'feature' }
  let!(:release) { create(:release, tag: ref, project: project) }
  let(:user) { create(:user) }
  let(:badge) do
    Gitlab::Ci::Badge::Release::LatestRelease.new(project, user)
  end

  let(:metadata) { described_class.new(badge) }

  before do
    project.add_guest(user)
  end

  it_behaves_like 'badge metadata'

  describe '#title' do
    it 'returns latest release title' do
      expect(metadata.title).to eq 'Latest Release'
    end
  end

  describe '#image_url' do
    it 'returns valid url' do
      expect(metadata.image_url).to include "/-/badges/release.svg"
    end
  end

  describe '#link_url' do
    it 'returns valid link' do
      expect(metadata.link_url).to include "/-/releases"
    end
  end
end
