require 'spec_helper'

describe SlackSlashCommandsService, models: true do
  it { is_expected.to respond_to :presenter_format }
end
