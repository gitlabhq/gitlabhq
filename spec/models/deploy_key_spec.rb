require 'spec_helper'

describe DeployKey, models: true do
  describe "Associations" do
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:projects) }
  end
end
