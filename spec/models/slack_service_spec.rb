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

      it { should validate_presence_of :room }
      it { should validate_presence_of :subdomain }
      it { should validate_presence_of :token }
    end
  end

  describe "Execute" do
    let(:slack) { SlackService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:sample_data) { GitPushService.new.sample_data(project, user) }
    let(:subdomain) { 'gitlab' }
    let(:token) { 'verySecret' }
    let(:api_url) {
      "https://#{subdomain}.slack.com/services/hooks/incoming-webhook?token=#{token}"
    }

    before do
      slack.stub(
        project: project,
        project_id: project.id,
        room: '#gitlab',
        service_hook: true,
        subdomain: subdomain,
        token: token
      )

      WebMock.stub_request(:post, api_url)
    end

    it "should call Slack API" do
      slack.execute(sample_data)

      expect(WebMock).to have_requested(:post, api_url).once
    end
  end
end
