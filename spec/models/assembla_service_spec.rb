# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#

require 'spec_helper'

describe AssemblaService do
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @assembla_service = AssemblaService.new
      @assembla_service.stub(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret',
        subdomain: 'project_name'
      )
      @sample_data = GitPushService.new.sample_data(project, user)
      @api_url = 'https://atlas.assembla.com/spaces/project_name/github_tool?secret_key=verySecret'
      WebMock.stub_request(:post, @api_url)
    end

    it "should call Assembla API" do
      @assembla_service.execute(@sample_data)
      WebMock.should have_requested(:post, @api_url).with(
        body: /#{@sample_data[:before]}.*#{@sample_data[:after]}.*#{project.path}/
      ).once
    end
  end
end
