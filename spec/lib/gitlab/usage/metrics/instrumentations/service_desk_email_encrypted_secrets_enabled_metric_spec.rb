# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ServiceDeskEmailEncryptedSecretsEnabledMetric,
  feature_category: :service_ping do
  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'ruby' } do
    let(:expected_value) { ::Gitlab::Email::ServiceDeskEmail.encrypted_secrets.active? }
  end
end
