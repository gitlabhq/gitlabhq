# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MetricsController, type: :request, feature_category: :observability do
  it_behaves_like 'Base action controller' do
    subject(:request) { get metrics_path }
  end
end
