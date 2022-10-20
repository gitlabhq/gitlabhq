# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::MergeRequestWidgetExtensionMetric,
  :clean_gitlab_redis_shared_state do
  before do
    4.times do
      Gitlab::UsageDataCounters::MergeRequestWidgetExtensionCounter.count(:terraform_count_expand)
    end
  end

  let(:expected_value) { 4 }

  it_behaves_like 'a correct instrumented metric value', {
    options: { event: 'expand', widget: 'terraform' },
    time_frame: 'all'
  }

  it 'raises an exception if widget option is not present' do
    expect do
      described_class.new(options: { event: 'expand' }, time_frame: 'all')
    end.to raise_error(ArgumentError, /'widget' option is required/)
  end
end
