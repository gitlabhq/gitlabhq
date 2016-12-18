require 'spec_helper'

describe SlackNotificationService, models: true do
  it_behaves_like "slack or mattermost"
end
