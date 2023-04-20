# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DatabaseMode, feature_category: :cell do
  let(:expected_value) { Gitlab::Database.database_mode }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
end
