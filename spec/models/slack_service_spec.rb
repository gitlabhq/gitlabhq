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

describe SlackService do
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { should validate_presence_of :webhook }
    end
  end

  describe "Execute" do
    let(:slack) { SlackService.new }
    let(:slack_service) { SlackService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:sample_data) { GitPushService.new.sample_data(project, user) }
    let(:webhook) { 'https://gitlabhq.slack.com/services/hooks?token=cdIj4r4LfXUOySDUjp0tk3OI' }
    let(:new_webhook) { 'https://hooks.gitlabhq.slack.com/services/cdIj4r4LfXUOySDUjp0tk3OI' }
    let(:api_url) {
      'https://gitlabhq.slack.com/services/hooks/incoming-webhook?token=cdIj4r4LfXUOySDUjp0tk3OI'
    }

    before do
      slack.stub(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook
      )

      WebMock.stub_request(:post, api_url)
    end

    it "should call Slack API" do
      slack.execute(sample_data)

      WebMock.should have_requested(:post, api_url).once
    end

    context 'with new webhook syntax' do
      before do
        slack_service.stub(
          project: project,
          project_id: project.id,
          service_hook: true,
          webhook: new_webhook
        )

        WebMock.stub_request(:post, api_url)
      end

      it "should call Slack API" do
        slack_service.execute(sample_data)

        WebMock.should have_requested(:post, api_url).once
      end
    end
  end
end
