require 'spec_helper'

describe SlackIntegration, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:service) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:team_id) }
    it { is_expected.to validate_presence_of(:team_name) }
    it { is_expected.to validate_presence_of(:alias) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:service) }
  end
end
