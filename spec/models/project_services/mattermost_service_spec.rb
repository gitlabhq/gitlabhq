require 'spec_helper'

describe MattermostService, models: true do
  it_behaves_like "slack or mattermost"
end
