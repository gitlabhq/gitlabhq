# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventEligibilityChecker, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  describe '#eligible?' do
    let(:checker) { described_class.new }

    subject { checker.eligible?(event_name) }

    where(:event_name, :product_usage_data_enabled, :result) do
      'perform_completion_worker' | true  | true
      'perform_completion_worker' | false | true
      'some_other_event'          | true  | true
      'some_other_event'          | false | false
    end

    before do
      allow(Gitlab::CurrentSettings).to receive(:product_usage_data_enabled?).and_return(product_usage_data_enabled)
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end
end
