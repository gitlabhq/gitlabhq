# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::PublishEventWorker, feature_category: :release_evidence do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:release) { create(:release, project: project, released_at: Time.current) }

  before do
    allow(Gitlab::EventStore).to receive(:publish).and_return(true)
  end

  describe 'when the releases feature is not disabled' do
    before do
      project.update!(releases_access_level: 'enabled')
      described_class.new.perform
    end

    it 'broadcasts the published event' do
      expect(Gitlab::EventStore).to have_received(:publish).with(Projects::ReleasePublishedEvent)
    end

    it 'sets the release as published' do
      expect(release.release_published_at).not_to be_nil
    end
  end

  describe 'when the releases feature is disabled' do
    before do
      project.update!(releases_access_level: 'disabled')
      described_class.new.perform
    end

    it 'does not broadcasts the published event' do
      expect(Gitlab::EventStore).not_to have_received(:publish).with(Projects::ReleasePublishedEvent)
    end

    # Having a release created with the releases feature disabled is a bogus state anyway.
    # Setting it as published prevents having such releases piling up forever in the
    # `unpublished` scope.
    it 'sets the release as published' do
      expect(release.release_published_at).not_to be_nil
    end
  end
end
