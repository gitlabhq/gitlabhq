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
    let(:token) { 'verySecret' }
    let(:server_url) { 'https://hipchat.example.com'}
    let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

    before(:each) do
      allow(hipchat).to receive_messages(
        project_id: project.id,
        project: project,
        room: 123456,
        server: server_url,
        token: token
      )
      WebMock.stub_request(:post, api_url)
    end

    it 'should test and return errors' do
      allow(hipchat).to receive(:execute).and_raise(StandardError, 'no such room')
      result = hipchat.test(push_sample_data)

      expect(result[:success]).to be_falsey
      expect(result[:result].to_s).to eq('no such room')
    end

    it 'should use v1 if version is provided' do
      allow(hipchat).to receive(:api_version).and_return('v1')
      expect(HipChat::Client).to receive(:new).
                                     with(token,
                                          api_version: 'v1',
                                          server_url: server_url).
                                     and_return(
                                         double(:hipchat_service).as_null_object)
      hipchat.execute(push_sample_data)
    end

    it 'should use v2 as the version when nothing is provided' do
      allow(hipchat).to receive(:api_version).and_return('')
      expect(HipChat::Client).to receive(:new).
                                     with(token,
                                          api_version: 'v2',
                                          server_url: server_url).
                                     and_return(
                                         double(:hipchat_service).as_null_object)
      hipchat.execute(push_sample_data)
    end

    context 'push events' do
      it "should call Hipchat API for push events" do
        hipchat.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "should create a push message" do
        message = hipchat.send(:create_push_message, push_sample_data)

        push_sample_data[:object_attributes]
        branch = push_sample_data[:ref].gsub('refs/heads/', '')
        expect(message).to include("#{user.name} pushed to branch " \
            "<a href=\"#{project.web_url}/commits/#{branch}\">#{branch}</a> of " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>")
      end
    end

    context 'tag_push events' do
      let(:push_sample_data) { Gitlab::PushDataBuilder.build(project, user, Gitlab::Git::BLANK_SHA, '1' * 40, 'refs/tags/test', []) }

      it "should call Hipchat API for tag push events" do
        hipchat.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "should create a tag push message" do
        message = hipchat.send(:create_push_message, push_sample_data)

        push_sample_data[:object_attributes]
        expect(message).to eq("#{user.name} pushed new tag " \
            "<a href=\"#{project.web_url}/commits/test\">test</a> to " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>\n")
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
        expect(message).to eq("#{user.name} opened " \
            "<a href=\"#{obj_attr[:url]}\">issue ##{obj_attr["iid"]}</a> in " \
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
        expect(message).to eq("#{user.name} opened " \
            "<a href=\"#{obj_attr[:url]}\">merge request ##{obj_attr["iid"]}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>Awesome merge request</b>" \
            "<pre>please fix</pre>")
      end
    end

    context "Note events" do
      let(:user) { create(:user) }
      let(:project) { create(:project, creator_id: user.id) }
      let(:issue)         { create(:issue, project: project) }
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let(:snippet)       { create(:project_snippet, project: project) }
      let(:commit_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
      let(:merge_request_note) { create(:note_on_merge_request, noteable_id: merge_request.id, note: "merge request note") }
      let(:issue_note) { create(:note_on_issue, noteable_id: issue.id, note: "issue note")}
      let(:snippet_note) { create(:note_on_project_snippet, noteable_id: snippet.id, note: "snippet note") }

      it "should call Hipchat API for commit comment events" do
        data = Gitlab::NoteDataBuilder.build(commit_note, user)
        hipchat.execute(data)

        expect(WebMock).to have_requested(:post, api_url).once

        message = hipchat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        commit_id = Commit.truncate_sha(data[:commit][:id])
        title = hipchat.send(:format_title, data[:commit][:message])

        expect(message).to eq("#{user.name} commented on " \
            "<a href=\"#{obj_attr[:url]}\">commit #{commit_id}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "#{title}" \
            "<pre>a comment on a commit</pre>")
      end

      it "should call Hipchat API for merge request comment events" do
        data = Gitlab::NoteDataBuilder.build(merge_request_note, user)
        hipchat.execute(data)

        expect(WebMock).to have_requested(:post, api_url).once

        message = hipchat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        merge_id = data[:merge_request]['iid']
        title = data[:merge_request]['title']

        expect(message).to eq("#{user.name} commented on " \
            "<a href=\"#{obj_attr[:url]}\">merge request ##{merge_id}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>#{title}</b>" \
            "<pre>merge request note</pre>")
      end

      it "should call Hipchat API for issue comment events" do
        data = Gitlab::NoteDataBuilder.build(issue_note, user)
        hipchat.execute(data)

        message = hipchat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        issue_id = data[:issue]['iid']
        title = data[:issue]['title']

        expect(message).to eq("#{user.name} commented on " \
            "<a href=\"#{obj_attr[:url]}\">issue ##{issue_id}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>#{title}</b>" \
            "<pre>issue note</pre>")
      end

      it "should call Hipchat API for snippet comment events" do
        data = Gitlab::NoteDataBuilder.build(snippet_note, user)
        hipchat.execute(data)

        expect(WebMock).to have_requested(:post, api_url).once

        message = hipchat.send(:create_message, data)

        obj_attr = data[:object_attributes]
        snippet_id = data[:snippet]['id']
        title = data[:snippet]['title']

        expect(message).to eq("#{user.name} commented on " \
            "<a href=\"#{obj_attr[:url]}\">snippet ##{snippet_id}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>#{title}</b>" \
            "<pre>snippet note</pre>")
      end
    end

    context "#message_options" do
      it "should be set to the defaults" do
        expect(hipchat.send(:message_options)).to eq({ notify: false, color: 'yellow' })
      end

      it "should set notfiy to true" do
        allow(hipchat).to receive(:notify).and_return('1')
        expect(hipchat.send(:message_options)).to eq({ notify: true, color: 'yellow' })
      end

      it "should set the color" do
        allow(hipchat).to receive(:color).and_return('red')
        expect(hipchat.send(:message_options)).to eq({ notify: false, color: 'red' })
      end
    end
  end
end
