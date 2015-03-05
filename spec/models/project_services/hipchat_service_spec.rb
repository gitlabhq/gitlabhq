# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer          not null
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#

require 'spec_helper'

describe HipchatService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Execute" do
    let(:hipchat) { HipchatService.new }
    let(:user)    { create(:user, username: 'username') }
    let(:project) { create(:project, name: 'project') }
    let(:api_url) { 'https://hipchat.example.com/v2/room/123456/notification?auth_token=verySecret' }
    let(:project_name) { project.name_with_namespace.gsub(/\s/, '') }

    before(:each) do
      hipchat.stub(
        project_id: project.id,
        project: project,
        room: 123456,
        server: 'https://hipchat.example.com',
        token: 'verySecret'
      )
      WebMock.stub_request(:post, api_url)
    end

    context 'push events' do
      let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

      it "should call Hipchat API for push events" do
        hipchat.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end
    end

    context 'issue events' do
      let(:issue) { create(:issue, title: 'Awesome issue', description: 'please fix') }
      let(:issue_service) { Issues::CreateService.new(project, user) }
      let(:issues_sample_data) { issue_service.hook_data(issue, 'open') }

      it "should call Hipchat API for issue events" do
        hipchat.execute(issues_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "should create an issue message" do
        message = hipchat.send(:create_issue_message, issues_sample_data)

        obj_attr = issues_sample_data[:object_attributes]
        expect(message).to eq("#{user.username} opened issue " \
            "<a href=\"#{obj_attr[:url]}\">##{obj_attr["iid"]}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>Awesome issue</b>" \
            "<pre>please fix</pre>")
      end
    end

    context 'merge request events' do
      let(:merge_request) { create(:merge_request, description: 'please fix', title: 'Awesome merge request', target_project: project, source_project: project) }
      let(:merge_service) { MergeRequests::CreateService.new(project, user) }
      let(:merge_sample_data) { merge_service.hook_data(merge_request, 'open') }

      it "should call Hipchat API for merge requests events" do
        hipchat.execute(merge_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "should create a merge request message" do
        message = hipchat.send(:create_merge_request_message,
                               merge_sample_data)

        obj_attr = merge_sample_data[:object_attributes]
        expect(message).to eq("#{user.username} opened merge request " \
            "<a href=\"#{obj_attr[:url]}\">##{obj_attr["iid"]}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>Awesome merge request</b>" \
            "<pre>please fix</pre>")
      end
    end
  end
end
