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

describe BambooService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    context "when a password was previously set" do
      before do
        @bamboo_service = BambooService.create(
          project: create(:project),
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic',
            password: "password"
          }
        )
      end
  
      it "reset password if url changed" do
        @bamboo_service.bamboo_url = 'http://gitlab1.com'
        @bamboo_service.save
        expect(@bamboo_service.password).to be_nil
      end
  
      it "does not reset password if username changed" do
        @bamboo_service.username = "some_name"
        @bamboo_service.save
        expect(@bamboo_service.password).to eq("password")
      end

      it "does not reset password if new url is set together with password, even if it's the same password" do
        @bamboo_service.bamboo_url = 'http://gitlab_edited.com'
        @bamboo_service.password = 'password'
        @bamboo_service.save
        expect(@bamboo_service.password).to eq("password")
        expect(@bamboo_service.bamboo_url).to eq("http://gitlab_edited.com")
      end

      it "should reset password if url changed, even if setter called multiple times" do
        @bamboo_service.bamboo_url = 'http://gitlab1.com'
        @bamboo_service.bamboo_url = 'http://gitlab1.com'
        @bamboo_service.save
        expect(@bamboo_service.password).to be_nil
      end
    end
    
    context "when no password was previously set" do
      before do
        @bamboo_service = BambooService.create(
          project: create(:project),
          properties: {
            bamboo_url: 'http://gitlab.com',
            username: 'mic'
          }
        )
      end

      it "saves password if new url is set together with password" do
        @bamboo_service.bamboo_url = 'http://gitlab_edited.com'
        @bamboo_service.password = 'password'
        @bamboo_service.save
        expect(@bamboo_service.password).to eq("password")
        expect(@bamboo_service.bamboo_url).to eq("http://gitlab_edited.com")
      end

    end
  end
end
