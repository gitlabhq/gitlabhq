# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#  public      :boolean          default(FALSE), not null
#

require 'spec_helper'

describe DeployKey, models: true do
  let(:project) { create(:project) }
  let(:deploy_key) { create(:deploy_key, projects: [project]) }

  describe "Associations" do
    it { is_expected.to have_many(:deploy_keys_projects) }
    it { is_expected.to have_many(:projects) }
  end
end
