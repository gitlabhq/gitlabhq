# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ContainerRegistryDbEnabledMetric, feature_category: :service_ping do
  let(:expected_value) { Gitlab::CurrentSettings.container_registry_db_enabled }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
end
