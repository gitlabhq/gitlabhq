# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ml::Mlflow::RunInfo, feature_category: :mlops do
  let_it_be(:candidate) { build_stubbed(:ml_candidates, internal_id: 1) }

  subject { described_class.new(candidate).as_json }

  context 'when start_time is nil' do
    it { expect(subject[:start_time]).to eq(0) }
  end

  context 'when start_time is not nil' do
    before do
      allow(candidate).to receive(:start_time).and_return(1234)
    end

    it { expect(subject[:start_time]).to eq(1234) }
  end

  describe 'end_time' do
    context 'when nil' do
      it { is_expected.not_to have_key(:end_time) }
    end

    context 'when not nil' do
      before do
        allow(candidate).to receive(:end_time).and_return(1234)
      end

      it { expect(subject[:end_time]).to eq(1234) }
    end
  end

  describe 'run_name' do
    context 'when nil' do
      it { is_expected.not_to have_key(:run_name) }
    end

    context 'when not nil' do
      before do
        allow(candidate).to receive(:name).and_return('hello')
      end

      it { expect(subject[:run_name]).to eq('hello') }
    end
  end

  describe 'experiment_id' do
    it 'is the experiment iid as string' do
      expect(subject[:experiment_id]).to eq(candidate.experiment.iid.to_s)
    end
  end

  describe 'run_id' do
    it 'is the iid as string' do
      expect(subject[:run_id]).to eq(candidate.eid.to_s)
    end
  end

  describe 'run_uuid' do
    it 'is the iid as string' do
      expect(subject[:run_uuid]).to eq(candidate.eid.to_s)
    end
  end

  describe 'artifact_uri' do
    context 'when candidate does not belong to a model version' do
      it 'returns the ml package format of the artifact_uri' do
        expect(subject[:artifact_uri]).to eq("http://localhost/api/v4/projects/#{candidate.project_id}/packages/ml_models/candidate:#{candidate.internal_id}/files/")
      end
    end

    context 'when candidate belongs to a model version' do
      let!(:version) { create(:ml_model_versions, :with_package) }
      let!(:candidate) { version.candidate }

      it 'returns the model version format of the artifact_uri' do
        expect(subject[:artifact_uri]).to eq("http://localhost/api/v4/projects/#{candidate.project_id}/packages/ml_models/#{version.id}/files/")
      end
    end

    context 'when candidate has already a generic package' do
      let!(:candidate) { create(:ml_candidates, :with_generic_package, name: 'run1') }

      it 'returns the generic version format of the artifact_uri' do
        expect(subject[:artifact_uri]).to eq("http://localhost/api/v4/projects/#{candidate.project_id}/packages/generic#{candidate.artifact_root}")
      end
    end
  end

  describe 'lifecycle_stage' do
    it 'is active' do
      expect(subject[:lifecycle_stage]).to eq('active')
    end
  end
end
