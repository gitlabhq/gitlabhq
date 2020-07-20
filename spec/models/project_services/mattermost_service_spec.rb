# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MattermostService do
  it_behaves_like "slack or mattermost notifications", "Mattermost"
end
