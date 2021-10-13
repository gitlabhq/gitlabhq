# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ActiveUserCountMetric do
  before do
    create(:user)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'ruby' } do
    let(:expected_value) { ::User.active.count }
  end
end
