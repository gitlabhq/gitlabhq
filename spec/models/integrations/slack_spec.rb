# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Slack, feature_category: :integrations do
  it_behaves_like Integrations::SlackMattermostNotifier, 'Slack'
  it_behaves_like Integrations::Base::SlackNotification, factory: :integrations_slack do
    before do
      stub_request(:post, integration.webhook)
    end
  end

  it_behaves_like 'supports group mentions', :integrations_slack
end
