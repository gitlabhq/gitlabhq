# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DownloadableArtifactEntity, feature_category: :job_artifacts do
  let(:pipeline) { create(:ci_pipeline, :with_codequality_reports) }
  let(:user) { create(:user) }
  let(:request) { EntityRequest.new({ current_user: user }) }
  let(:entity) { described_class.new(pipeline, request: request) }

  before do
    pipeline.project.add_guest(user)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields', :aggregate_failures do
      expect(subject).to include(:artifacts)
      expect(subject[:artifacts].size).to eq(1)
    end

    context 'when user cannot read job artifact' do
      let!(:build) do
        create(:ci_build, :success, :private_artifacts, pipeline: pipeline)
      end

      it 'returns only artifacts readable by user', :aggregate_failures do
        expect(subject[:artifacts].size).to eq(1)
        expect(subject[:artifacts].first[:name]).to eq("test:codequality")
      end
    end
  end
end
