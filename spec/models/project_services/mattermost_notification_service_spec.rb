require 'spec_helper'

describe MattermostNotificationService, models: true do
  it_behaves_like "slack or mattermost"
end
