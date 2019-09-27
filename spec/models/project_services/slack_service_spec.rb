# frozen_string_literal: true

require 'spec_helper'

describe SlackService do
  it_behaves_like "slack or mattermost notifications", 'Slack'
end
