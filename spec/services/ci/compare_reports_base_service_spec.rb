# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareReportsBaseService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  describe '#latest?' do
    subject { service.latest?(base_pipeline, head_pipeline, data) }

    let!(:base_pipeline) { nil }
    let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }
    let!(:key) { service.send(:key, base_pipeline, head_pipeline) }

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
end
