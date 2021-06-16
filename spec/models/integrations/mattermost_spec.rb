# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Mattermost do
  it_behaves_like Integrations::SlackMattermostNotifier, "Mattermost"
end
