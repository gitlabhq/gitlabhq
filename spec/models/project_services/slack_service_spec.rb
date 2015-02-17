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
    let(:sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }
    let(:webhook_url) { 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685' }

    before do
      slack.stub(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    it "should call Slack API" do
      slack.execute(sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end
  end
end
