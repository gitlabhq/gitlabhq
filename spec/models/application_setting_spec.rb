require 'spec_helper'

describe ApplicationSetting, models: true do
  describe 'should exists on start' do
    it { ApplicationSetting.count.should_not be_zero }
  end
end
