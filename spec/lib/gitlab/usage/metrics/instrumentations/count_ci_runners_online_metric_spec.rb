# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCiRunnersOnlineMetric, feature_category: :runner_core do
  let_it_be(:group) { create(:group) }
  let(:expected_value) { 1 }

  before do
    create(:ci_runner, :group, :online, groups: [group])
    create(:ci_runner, :group, :offline, groups: [group])
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
