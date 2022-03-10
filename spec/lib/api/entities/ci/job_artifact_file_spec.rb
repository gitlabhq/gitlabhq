# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::JobArtifactFile do
  let(:artifact_file) { instance_double(JobArtifactUploader, filename: 'ci_build_artifacts.zip', cached_size: 42) }
  let(:entity) { described_class.new(artifact_file) }

  subject { entity.as_json }

  it 'returns the filename' do
    expect(subject[:filename]).to eq('ci_build_artifacts.zip')
  end

  it 'returns the size' do
    expect(subject[:size]).to eq(42)
  end
end
