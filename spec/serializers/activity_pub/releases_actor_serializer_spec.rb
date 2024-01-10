# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ReleasesActorSerializer, feature_category: :groups_and_projects do
  let(:project) { build_stubbed(:project, name: 'Fooify', path: 'fooify') }
  let(:releases) { build_stubbed_list(:release, 3, project: project) }

  context 'when there is a single object provided' do
    subject { described_class.new.represent(project, outbox: '/outbox', inbox: '/inbox') }

    it 'serializes the actor attributes' do
      expect(subject).to include(:id, :type, :preferredUsername, :name, :content, :context)
    end
  end
end
