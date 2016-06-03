# == Schema Information
#
# Table name: ci_triggers
#
#  id            :integer          not null, primary key
#  token         :string(255)
#  project_id    :integer
#  deleted_at    :datetime
#  created_at    :datetime
#  updated_at    :datetime
#  gl_project_id :integer
#

require 'spec_helper'

describe Ci::Trigger, models: true do
  let(:project) { FactoryGirl.create :empty_project }

  describe 'before_validation' do
    it 'should set an random token if none provided' do
      trigger = FactoryGirl.create :ci_trigger_without_token, project: project
      expect(trigger.token).not_to be_nil
    end

    it 'should not set an random token if one provided' do
      trigger = FactoryGirl.create :ci_trigger, project: project
      expect(trigger.token).to eq('token')
    end
  end
end
