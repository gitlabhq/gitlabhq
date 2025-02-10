# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::MattermostSlashCommands, feature_category: :integrations do
  it_behaves_like Integrations::Base::SlashCommands
  it_behaves_like Integrations::Base::MattermostSlashCommands
end
