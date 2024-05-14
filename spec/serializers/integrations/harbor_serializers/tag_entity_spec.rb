# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HarborSerializers::TagEntity do
  let_it_be(:harbor_integration) { create(:harbor_integration) }

  let(:push_time) { "2022-03-22T09:04:56.186Z" }
  let(:pull_time) { "2022-03-23T09:04:56.186Z" }

  let(:tag) do
    {
      artifact_id: 5,
      id: 6,
      immutable: false,
      name: "1",
      push_time: push_time,
      pull_time: pull_time,
      repository_id: 5,
      signed: false
    }.deep_stringify_keys
  end

  subject { described_class.new(tag).as_json }

  it 'returns the Harbor artifact' do
    expect(subject).to include({
      harbor_repository_id: 5,
      harbor_artifact_id: 5,
      harbor_id: 6,
      name: "1",
      pull_time: pull_time.to_datetime.utc,
      push_time: push_time.to_datetime.utc,
      signed: false,
      immutable: false
    })
  end
end
