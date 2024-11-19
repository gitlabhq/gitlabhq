# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountServiceDeskCustomEmailEnabledMetric, feature_category: :service_ping do
  let_it_be(:project) { create(:project) }
  let_it_be(:credential) { build(:service_desk_custom_email_credential, project: project).save!(validate: false) }
  let_it_be(:verification) { create(:service_desk_custom_email_verification, :finished, project: project) }
  let_it_be(:setting) do
    create(:service_desk_setting, project: project, custom_email: 'support@example.com', custom_email_enabled: true)
  end

  let(:expected_value) { 1 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end
