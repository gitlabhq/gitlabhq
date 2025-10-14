# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RelativeUrlInstallMetric, feature_category: :service_ping do
  context 'when relative_url_root is present' do
    before do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('/gitlab')
    end

    let(:expected_value) { true }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end

  context 'when relative_url_root is an empty string' do
    before do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return('')
    end

    let(:expected_value) { false }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end

  context 'when relative_url_root is nil' do
    before do
      allow(Gitlab.config.gitlab).to receive(:relative_url_root).and_return(nil)
    end

    let(:expected_value) { false }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end
