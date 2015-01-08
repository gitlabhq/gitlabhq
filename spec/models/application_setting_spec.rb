require 'spec_helper'

describe ApplicationSetting, models: true do
  it { ApplicationSetting.create_from_defaults.should be_valid }
end
