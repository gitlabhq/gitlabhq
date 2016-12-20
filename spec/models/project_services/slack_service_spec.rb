require 'spec_helper'

describe SlackService, models: true do
  it_behaves_like "slack or mattermost notifications"
end
