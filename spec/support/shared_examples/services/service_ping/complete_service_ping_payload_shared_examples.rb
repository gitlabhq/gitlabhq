# frozen_string_literal: true

RSpec.shared_examples 'complete service ping payload' do
  it_behaves_like 'service ping payload with all expected metrics' do
    let(:expected_metrics) do
      standard_metrics + subscription_metrics + operational_metrics + optional_metrics
    end
  end
end
