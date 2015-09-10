require 'spec_helper'

describe Ci::Trigger do
  let(:project) { FactoryGirl.create :ci_project }

  describe 'before_validation' do
    it 'should set an random token if none provided' do
      trigger = FactoryGirl.create :ci_trigger_without_token, project: project
      trigger.token.should_not be_nil
    end

    it 'should not set an random token if one provided' do
      trigger = FactoryGirl.create :ci_trigger, project: project
      trigger.token.should == 'token'
    end
  end
end
