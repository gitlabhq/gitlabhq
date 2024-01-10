# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::PublishReleaseActivitySerializer, feature_category: :release_orchestration do
  let(:release) { build_stubbed(:release) }

  let(:serializer) { described_class.new.represent(release) }

  it 'serializes the activity attributes' do
    expect(serializer).to include(:id, :type, :actor, :object)
  end
end
