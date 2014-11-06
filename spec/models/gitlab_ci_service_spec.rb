# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe GitlabCiService do
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Mass assignment" do
  end

  describe 'commits methods' do
    before do
      @service = GitlabCiService.new
      @service.stub(
        service_hook: true,
        project_url: 'http://ci.gitlab.org/projects/2',
        token: 'verySecret'
      )
    end

    describe :commit_status_path do
      it { @service.commit_status_path("2ab7834c").should == "http://ci.gitlab.org/projects/2/commits/2ab7834c/status.json?token=verySecret"}
    end

    describe :build_page do
      it { @service.build_page("2ab7834c").should == "http://ci.gitlab.org/projects/2/commits/2ab7834c"}
    end
  end
end
