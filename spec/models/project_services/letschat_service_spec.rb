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
require 'pp'

describe LetschatService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Execute' do
    let(:letschat) { LetschatService.new }
    let(:user) { create(:user, username: 'username') }
    let(:project) { create(:project, name: 'project') }
    let(:project_name) { project.name_with_namespace.gsub(/\s/, '') }
    let(:token) { 'verySecret' }
    let(:server) { 'https://letschat.example.com' }

    before(:each) do
      letschat.stub(
        project: project,
        project_id: project.id,
        token: token,
        server: server,
        room: '123456'
      )
      WebMock.stub_request(:post , /#{server}/)
    end

    context 'push events' do
      let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

      it "should call Letschat API for push events" do
        letschat.execute(push_sample_data)
        expect(WebMock).to have_requested(:post, /#{server}/).once
      end

      it "should create a push message" do
        message = letschat.send(:create_push_message, push_sample_data)

        branch = push_sample_data[:ref].gsub('refs/heads/', '')
        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(project.web_url)
        expect(message).to include(branch)
      end
    end

    context 'tag_push events' do
      let(:push_sample_data) { Gitlab::PushDataBuilder.build(project, user, Gitlab::Git::BLANK_SHA, '1'*40, 'refs/tags/test', []) }

      it "should call Letschat API for tag push events" do
        letschat.execute(push_sample_data)
        expect(WebMock).to have_requested(:post, /#{server}/).once
      end

      it "should create a tag push message" do
        message = letschat.send(:create_push_message, push_sample_data)

        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(project.web_url)
      end
    end

    context 'issue events' do
      let(:issue) { create(:issue, title: 'Awesome issue', description: 'please fix') }
      let(:issue_service) { Issues::CreateService.new(project, user) }
      let(:issues_sample_data) { issue_service.hook_data(issue, 'open') }

      it "should call Letschat API for issue events" do
        letschat.execute(issues_sample_data)
        expect(WebMock).to have_requested(:post, /#{server}/).once
      end

      it "should create an issue message" do
        message = letschat.send(:create_issue_message, issues_sample_data)

        obj_attr = issues_sample_data[:object_attributes]
        iid = obj_attr["iid"]
        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(obj_attr[:url])
        expect(message).to include("issue ##{iid}")
      end
    end

    context 'merge request events' do
      let(:merge_request) { create(:merge_request, description: 'please fix', title: 'Awesome merge request', target_project: project, source_project: project) }
      let(:merge_service) { MergeRequests::CreateService.new(project, user) }
      let(:merge_sample_data) { merge_service.hook_data(merge_request, 'open') }

      it "should call Letschat API for merge request events" do
        letschat.execute(merge_sample_data)
        expect(WebMock).to have_requested(:post, /#{server}/).once
      end

      it "should create a merge request message" do
        message = letschat.send(:create_merge_request_message, merge_sample_data)

        obj_attr = merge_sample_data[:object_attributes]
        iid = obj_attr["iid"]
        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(obj_attr[:url])
        expect(message).to include("merge request ##{iid}")
      end
    end

    context 'Note events' do
      let(:commit_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:merge_request_note) { create(:note_on_merge_request, noteable_id: merge_request.id, note: "merge request note") }
      let(:issue) { create(:issue, project: project) }
      let(:issue_note) { create(:note_on_issue, noteable_id: issue.id, note: "issue note") }
      let(:snippet) { create(:project_snippet, project: project) }
      let(:snippet_note) { create(:note_on_project_snippet, noteable_id: snippet.id, note: "snippet note") }

      it "should call Letschat API for commit comment events" do
        data = Gitlab::NoteDataBuilder.build(commit_note, user)
        letschat.execute(data)
        expect(WebMock).to have_requested(:post, /#{server}/).once

        message = letschat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        commit_id = Commit.truncate_sha(data[:commit][:id])
        title = letschat.send(:format_title, data[:commit][:message])

        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(obj_attr[:url])
        expect(message).to include(title)
        expect(message).to include("commit #{commit_id}")
      end

      it "should call Letschat API for merge request comment events" do
        data = Gitlab::NoteDataBuilder.build(merge_request_note, user)
        letschat.execute(data)
        expect(WebMock).to have_requested(:post, /#{server}/).once

        message = letschat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        merge_id = data[:merge_request]['iid']
        title = data[:merge_request]['title']

        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(obj_attr[:url])
        expect(message).to include(title)
        expect(message).to include("merge request ##{merge_id}")
      end

      it "should call Letschat API for issue comment events" do
        data = Gitlab::NoteDataBuilder.build(issue_note, user)
        letschat.execute(data)
        expect(WebMock).to have_requested(:post, /#{server}/).once

        message = letschat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        issue_id = data[:issue]['iid']
        title = data[:issue]['title']

        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(obj_attr[:url])
        expect(message).to include("issue ##{issue_id}")
      end

      it "should call Letschat API for snippet comment events" do
        data = Gitlab::NoteDataBuilder.build(snippet_note, user)
        letschat.execute(data)
        expect(WebMock).to have_requested(:post, /#{server}/).once

        message = letschat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        snippet_id = data[:snippet]['id']
        title = data[:snippet]['title']

        expect(message).to include(project_name)
        expect(message).to include(user.name)
        expect(message).to include(obj_attr[:url])
        expect(message).to include("snippet ##{snippet_id}")
      end
    end

    context "#message_options" do
      it "should be set to the defaults" do
        expect(letschat.send(:message_options)).to eq({ notify: false, color: 'yellow' })
      end

      it "should set notify to true" do
        letschat.stub(notify: '1')
        expect(letschat.send(:message_options)).to eq({ notify: true, color: 'yellow' })
      end

      it "should set the color" do
        letschat.stub(color: 'red')
        expect(letschat.send(:message_options)).to eq({ notify: false, color: 'red' })
      end
    end

  end
end
