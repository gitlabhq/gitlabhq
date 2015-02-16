# == Schema Information
#
# Table name: deploy_keys_projects
#
#  id            :integer          not null, primary key
#  deploy_key_id :integer          not null
#  project_id    :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe DeployKeysProject do
  describe "Associations" do
    it { is_expected.to belong_to(:deploy_key) }
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:deploy_key_id) }
  end
end
