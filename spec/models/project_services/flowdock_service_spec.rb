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

describe FlowdockService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project) }

    before do
      @flowdock_service = FlowdockService.new
      allow(@flowdock_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        token: 'verySecret'
      )
      @sample_data = Gitlab::PushDataBuilder.build_sample(project, user)
      @api_url = 'https://api.flowdock.com/v1/messages'
      WebMock.stub_request(:post, @api_url)
    end

    it "should call FlowDock API" do
      @flowdock_service.execute(@sample_data)
      @sample_data[:commits].each do |commit|
        # One request to Flowdock per new commit
        next if commit[:id] == @sample_data[:before]
        expect(WebMock).to have_requested(:post, @api_url).with(
          body: /#{commit[:id]}.*#{project.path}/
        ).once
      end
    end
  end
end
