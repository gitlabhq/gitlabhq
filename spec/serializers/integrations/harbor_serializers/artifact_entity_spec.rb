# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HarborSerializers::ArtifactEntity, feature_category: :container_registry do
  let_it_be(:harbor_integration) { create(:harbor_integration) }

  let(:artifact) do
    {
      digest: "sha256:14d4f50961544fdb669075c442509f194bdc4c0e344bde06e35dbd55af842a38",
      id: 5,
      project_id: 14,
      push_time: "2022-03-22T09:04:56.170Z",
      repository_id: 5,
      size: 774790,
      tags: [
        {
          artifact_id: 5,
          id: 7,
          immutable: false,
          name: "2",
          push_time: "2022-03-22T09:05:04.844Z",
          repository_id: 5,
          signed: false
        },
        {
          artifact_id: 5,
          id: 6,
          immutable: false,
          name: "1",
          push_time: "2022-03-22T09:04:56.186Z",
          repository_id: 5,
          signed: false
        }
      ],
      type: "IMAGE"
    }.deep_stringify_keys
  end

  subject { described_class.new(artifact).as_json }

  it 'returns the Harbor artifact' do
    expect(subject).to include({
      harbor_id: 5,
      size: 774790,
      push_time: "2022-03-22T09:04:56.170Z".to_datetime,
      digest: "sha256:14d4f50961544fdb669075c442509f194bdc4c0e344bde06e35dbd55af842a38",
      tags: %w[2 1]
    })
  end

  context 'with data that may contain path traversal attacks' do
    before do
      artifact['digest'] = './../../../../../etc/hosts'
    end

    it 'logs an error and forbids the path traversal values' do
      expect(::Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(::Gitlab::PathTraversal::PathTraversalAttackError),
        message: /Path traversal attack detected/,
        class: described_class.name
      )

      expect(subject[:digest]).to eq('')
    end
  end
end
