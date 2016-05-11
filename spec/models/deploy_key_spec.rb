require 'spec_helper'

describe DeployKey, models: true do
  let(:project) { create(:project) }
  let(:deploy_key) { create(:deploy_key, projects: [project]) }

  describe "Associations" do
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:projects) }
  end
end
