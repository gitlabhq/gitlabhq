# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiRunnersGroupTypeActiveOnlineMetric, feature_category: :runner do
  let_it_be(:group) { create(:group) }
  let(:expected_value) { 1 }

  before do
    create(:ci_runner, :group, groups: [group], contacted_at: 1.second.ago)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
