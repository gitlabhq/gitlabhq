# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::IncomingEmailEncryptedSecretsEnabledMetric,
  feature_category: :service_ping do
  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'ruby' } do
    let(:expected_value) { ::Gitlab::Email::IncomingEmail.encrypted_secrets.active? }
  end
end
