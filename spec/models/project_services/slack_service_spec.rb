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
#

require 'spec_helper'

describe SlackService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :webhook }
    end
  end

  describe "Execute" do
    let(:slack)   { SlackService.new }
    let(:user)    { create(:user) }
    let(:project) { create(:project) }
    let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }
    let(:webhook_url) { 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685' }
    let(:username) { 'slack_username' }
    let(:channel) { 'slack_channel' }

    before do
      slack.stub(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)

      opts = {
        title: 'Awesome issue',
        description: 'please fix'
      }

      issue_service = Issues::CreateService.new(project, user, opts)
      @issue = issue_service.execute
      @issues_sample_data = issue_service.hook_data(@issue, 'open')

      opts = {
        title: 'Awesome merge_request',
        description: 'please fix',
        source_branch: 'stable',
        target_branch: 'master'
      }
      merge_service = MergeRequests::CreateService.new(project,
                                                       user, opts)
      @merge_request = merge_service.execute
      @merge_sample_data = merge_service.hook_data(@merge_request,
                                                   'open')
    end

    it "should call Slack API for pull requests" do
      slack.execute(push_sample_data)

      WebMock.should have_requested(:post, webhook_url).once
    end

    it "should call Slack API for issue events" do
      slack.execute(@issues_sample_data)

      WebMock.should have_requested(:post, webhook_url).once
    end

    it "should call Slack API for merge requests events" do
      slack.execute(@merge_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it 'should use the username as an option for slack when configured' do
      slack.stub(username: username)
      expect(Slack::Notifier).to receive(:new).
        with(webhook_url, username: username).
        and_return(
          double(:slack_service).as_null_object
        )
      slack.execute(push_sample_data)
    end

    it 'should use the channel as an option when it is configured' do
      slack.stub(channel: channel)
      expect(Slack::Notifier).to receive(:new).
        with(webhook_url, channel: channel).
        and_return(
          double(:slack_service).as_null_object
        )
      slack.execute(push_sample_data)
    end
  end
end
