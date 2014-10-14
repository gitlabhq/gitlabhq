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

describe GemnasiumService do
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @gemnasium_service = GemnasiumService.new
      @gemnasium_service.stub(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        api_key: 'GemnasiumUserApiKey'
      )
      @sample_data = GitPushService.new.sample_data(project, user)
    end
    it "should call Gemnasium service" do
      Gemnasium::GitlabService.should_receive(:execute).with(an_instance_of(Hash)).once
      @gemnasium_service.execute(@sample_data)
    end
  end
end
