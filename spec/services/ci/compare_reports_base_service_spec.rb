# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareReportsBaseService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  let!(:base_pipeline) { nil }
  let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }
  let!(:key) { service.send(:key, base_pipeline, head_pipeline) }

  describe '#latest?' do
    subject { service.latest?(base_pipeline, head_pipeline, data) }

    context 'when cache key is latest' do
      let(:data) { { key: key } }

      it { is_expected.to be_truthy }
    end

    context 'when cache key is outdated' do
      before do
        head_pipeline.update_column(:updated_at, 10.minutes.ago)
      end

      let(:data) { { key: key } }

      it { is_expected.to be_falsy }
    end

    context 'when cache key is empty' do
      let(:data) { { key: nil } }

      it { is_expected.to be_falsy }
    end
  end

  describe '#execute' do
    context 'when base_pipeline is running' do
      let!(:base_pipeline) { create(:ci_pipeline, :running, project: project) }

      subject { service.execute(base_pipeline, head_pipeline) }

      it { is_expected.to eq(status: :parsing, key: key) }
    end
  end
end
