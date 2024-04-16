# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Mattermost, feature_category: :integrations do
  it_behaves_like Integrations::SlackMattermostNotifier, "Mattermost"
  it_behaves_like Integrations::HasAvatar
end
