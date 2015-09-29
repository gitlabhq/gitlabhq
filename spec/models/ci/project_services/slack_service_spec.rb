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

describe Ci::SlackService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
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
    let(:slack)   { Ci::SlackService.new }
    let(:commit)  { FactoryGirl.create :ci_commit }
    let(:build)   { FactoryGirl.create :ci_build, commit: commit, status: 'failed' }
    let(:webhook_url) { 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685' }
    let(:notify_only_broken_builds) { false }

    before do
      allow(slack).to receive_messages(
        project: commit.project,
        project_id: commit.project_id,
        webhook: webhook_url,
        notify_only_broken_builds: notify_only_broken_builds
      )

      WebMock.stub_request(:post, webhook_url)
    end

    it "should call Slack API" do
      slack.execute(build)
      Ci::SlackNotifierWorker.drain

      expect(WebMock).to have_requested(:post, webhook_url).once
    end
  end
end
