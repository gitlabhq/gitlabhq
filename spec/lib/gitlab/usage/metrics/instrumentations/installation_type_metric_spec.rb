# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::InstallationTypeMetric, feature_category: :service_ping do
  context 'when Rails.env is production' do
    before do
      allow(Rails).to receive_message_chain(:env, :production?).and_return(true)
    end

    let(:expected_value) { Gitlab::INSTALLATION_TYPE }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
  end

  context 'with Rails.env is not production' do
    let(:expected_value) { 'gitlab-development-kit' }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
  end
end
