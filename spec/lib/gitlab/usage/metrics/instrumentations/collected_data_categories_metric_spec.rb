# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../support/shared_examples/metrics_instrumentation_shared_examples'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CollectedDataCategoriesMetric do
  it_behaves_like 'a correct instrumented metric value', {} do
    let(:expected_value) { %w[standard subscription operational optional] }

    before do
      allow_next_instance_of(ServicePing::PermitDataCategories) do |instance|
        expect(instance).to receive(:execute).and_return(expected_value)
      end
    end
  end
end
