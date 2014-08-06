# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  recipients  :text
#  api_key     :string(255)
#  username    :string(255)
#  password    :string(255)
#  api_version    :string(255)

require 'spec_helper'

describe JiraService, models: true do
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @jira_service = JiraService.new
      @jira_service.stub(
        project_id: project.id,
        project: project,
        service_hook: true,
        project_url: 'http://jira.example.com',
        username: 'gitlab_jira_username',
        password: 'gitlab_jira_password',
        api_version: '2'
      )
      @sample_data = GitPushService.new.sample_data(project, user)
      # https://github.com/bblimke/webmock#request-with-basic-authentication
      @api_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/transitions'

      WebMock.stub_request(:post, @api_url)
    end

    it "should call JIRA API" do
      @jira_service.execute(@sample_data, JiraIssue.new("JIRA-123"))
      WebMock.should have_requested(:post, @api_url).with(
        body: /Issue solved with/
      ).once
    end
  end
end
