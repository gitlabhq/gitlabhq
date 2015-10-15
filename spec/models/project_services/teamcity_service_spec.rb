# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe TeamcityService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @teamcity_service = TeamcityService.create(
        project: create(:project),
        properties: {
          teamcity_url: 'http://gitlab.com',
          username: 'mic',
          password: "password"
        }
      )
    end

    it "reset password if url changed" do
      @teamcity_service.teamcity_url = 'http://gitlab1.com'
      @teamcity_service.save
      expect(@teamcity_service.password).to be_nil
    end

    it "does not reset password if username changed" do
      @teamcity_service.username = "some_name"
      @teamcity_service.save
      expect(@teamcity_service.password).to eq("password")
    end
  end
end
