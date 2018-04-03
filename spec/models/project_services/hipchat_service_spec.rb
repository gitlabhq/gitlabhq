require 'spec_helper'

describe HipchatService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe "Execute" do
    let(:hipchat) { described_class.new }
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:api_url) { 'https://hipchat.example.com/v2/room/123456/notification?auth_token=verySecret' }
    let(:project_name) { project.name_with_namespace.gsub(/\s/, '') }
    let(:token) { 'verySecret' }
    let(:server_url) { 'https://hipchat.example.com'}
    let(:push_sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    before do
      allow(hipchat).to receive_messages(
        project_id: project.id,
        project: project,
        room: 123456,
        server: server_url,
        token: token
      )
      WebMock.stub_request(:post, api_url)
    end

    it 'tests and return errors' do
      allow(hipchat).to receive(:execute).and_raise(StandardError, 'no such room')
      result = hipchat.test(push_sample_data)

      expect(result[:success]).to be_falsey
      expect(result[:result].to_s).to eq('no such room')
    end

    it 'uses v1 if version is provided' do
      allow(hipchat).to receive(:api_version).and_return('v1')
      expect(HipChat::Client).to receive(:new).with(
        token,
        api_version: 'v1',
        server_url: server_url
      ).and_return(double(:hipchat_service).as_null_object)
      hipchat.execute(push_sample_data)
    end

    it 'uses v2 as the version when nothing is provided' do
      allow(hipchat).to receive(:api_version).and_return('')
      expect(HipChat::Client).to receive(:new).with(
        token,
        api_version: 'v2',
        server_url: server_url
      ).and_return(double(:hipchat_service).as_null_object)
      hipchat.execute(push_sample_data)
    end

    context 'push events' do
      it "calls Hipchat API for push events" do
        hipchat.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "creates a push message" do
        message = hipchat.send(:create_push_message, push_sample_data)

        push_sample_data[:object_attributes]
        branch = push_sample_data[:ref].gsub('refs/heads/', '')
        expect(message).to include("#{user.name} pushed to branch " \
            "<a href=\"#{project.web_url}/commits/#{branch}\">#{branch}</a> of " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>")
      end
    end

    context 'tag_push events' do
      let(:push_sample_data) do
        Gitlab::DataBuilder::Push.build(
          project,
          user,
          Gitlab::Git::BLANK_SHA,
          '1' * 40,
          'refs/tags/test',
          [])
      end

      it "calls Hipchat API for tag push events" do
        hipchat.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "creates a tag push message" do
        message = hipchat.send(:create_push_message, push_sample_data)

        push_sample_data[:object_attributes]
        expect(message).to eq("#{user.name} pushed new tag " \
            "<a href=\"#{project.web_url}/commits/test\">test</a> to " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>\n")
      end
    end

    context 'issue events' do
      let(:issue) { create(:issue, title: 'Awesome issue', description: '**please** fix') }
      let(:issue_service) { Issues::CreateService.new(project, user) }
      let(:issues_sample_data) { issue_service.hook_data(issue, 'open') }

      it "calls Hipchat API for issue events" do
        hipchat.execute(issues_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "creates an issue message" do
        message = hipchat.send(:create_issue_message, issues_sample_data)

        obj_attr = issues_sample_data[:object_attributes]
        expect(message).to eq("#{user.name} opened " \
            "<a href=\"#{obj_attr[:url]}\">issue ##{obj_attr["iid"]}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>Awesome issue</b>" \
            "<pre><strong>please</strong> fix</pre>")
      end
    end

    context 'merge request events' do
      let(:merge_request) { create(:merge_request, description: '**please** fix', title: 'Awesome merge request', target_project: project, source_project: project) }
      let(:merge_service) { MergeRequests::CreateService.new(project, user) }
      let(:merge_sample_data) { merge_service.hook_data(merge_request, 'open') }

      it "calls Hipchat API for merge requests events" do
        hipchat.execute(merge_sample_data)

        expect(WebMock).to have_requested(:post, api_url).once
      end

      it "creates a merge request message" do
        message = hipchat.send(:create_merge_request_message,
                               merge_sample_data)

        obj_attr = merge_sample_data[:object_attributes]
        expect(message).to eq("#{user.name} opened " \
            "<a href=\"#{obj_attr[:url]}\">merge request !#{obj_attr["iid"]}</a> in " \
            "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
            "<b>Awesome merge request</b>" \
            "<pre><strong>please</strong> fix</pre>")
      end
    end

    context "Note events" do
      let(:user) { create(:user) }
      let(:project) { create(:project, :repository, creator: user) }

      context 'when commit comment event triggered' do
        let(:commit_note) do
          create(:note_on_commit, author: user, project: project,
                                  commit_id: project.repository.commit.id,
                                  note: 'a comment on a commit')
        end

        it "calls Hipchat API for commit comment events" do
          data = Gitlab::DataBuilder::Note.build(commit_note, user)
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
      end

      context 'when merge request comment event triggered' do
        let(:merge_request) do
          create(:merge_request, source_project: project,
                                 target_project: project)
        end

        let(:merge_request_note) do
          create(:note_on_merge_request, noteable: merge_request,
                                         project: project,
                                         note: "merge request **note**")
        end

        it "calls Hipchat API for merge request comment events" do
          data = Gitlab::DataBuilder::Note.build(merge_request_note, user)
          hipchat.execute(data)

          expect(WebMock).to have_requested(:post, api_url).once

          message = hipchat.send(:create_message, data)

          obj_attr = data[:object_attributes]
          merge_id = data[:merge_request]['iid']
          title = data[:merge_request]['title']

          expect(message).to eq("#{user.name} commented on " \
              "<a href=\"#{obj_attr[:url]}\">merge request !#{merge_id}</a> in " \
              "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
              "<b>#{title}</b>" \
              "<pre>merge request <strong>note</strong></pre>")
        end
      end

      context 'when issue comment event triggered' do
        let(:issue) { create(:issue, project: project) }
        let(:issue_note) do
          create(:note_on_issue, noteable: issue, project: project,
                                 note: "issue **note**")
        end

        it "calls Hipchat API for issue comment events" do
          data = Gitlab::DataBuilder::Note.build(issue_note, user)
          hipchat.execute(data)

          message = hipchat.send(:create_message, data)

          obj_attr = data[:object_attributes]
          issue_id = data[:issue]['iid']
          title = data[:issue]['title']

          expect(message).to eq("#{user.name} commented on " \
              "<a href=\"#{obj_attr[:url]}\">issue ##{issue_id}</a> in " \
              "<a href=\"#{project.web_url}\">#{project_name}</a>: " \
              "<b>#{title}</b>" \
              "<pre>issue <strong>note</strong></pre>")
        end

        context 'with confidential issue' do
          before do
            issue.update!(confidential: true)
          end

          it 'calls Hipchat API with issue comment' do
            data = Gitlab::DataBuilder::Note.build(issue_note, user)
            hipchat.execute(data)

            message = hipchat.send(:create_message, data)

            expect(message).to include("<pre>issue <strong>note</strong></pre>")
          end
        end
      end

      context 'when snippet comment event triggered' do
        let(:snippet) { create(:project_snippet, project: project) }
        let(:snippet_note) do
          create(:note_on_project_snippet, noteable: snippet,
                                           project: project,
                                           note: "snippet note")
        end

        it "calls Hipchat API for snippet comment events" do
          data = Gitlab::DataBuilder::Note.build(snippet_note, user)
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
    end

    context 'pipeline events' do
      let(:pipeline) { create(:ci_empty_pipeline, user: create(:user)) }
      let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

      context 'for failed' do
        before do
          pipeline.drop
        end

        it "calls Hipchat API" do
          hipchat.execute(data)

          expect(WebMock).to have_requested(:post, api_url).once
        end

        it "creates a build message" do
          message = hipchat.__send__(:create_pipeline_message, data)

          project_url = project.web_url
          project_name = project.name_with_namespace.gsub(/\s/, '')
          pipeline_attributes = data[:object_attributes]
          ref = pipeline_attributes[:ref]
          ref_type = pipeline_attributes[:tag] ? 'tag' : 'branch'
          duration = pipeline_attributes[:duration]
          user_name = data[:user][:name]

          expect(message).to eq("<a href=\"#{project_url}\">#{project_name}</a>: " \
            "Pipeline <a href=\"#{project_url}/pipelines/#{pipeline.id}\">##{pipeline.id}</a> " \
            "of <a href=\"#{project_url}/commits/#{ref}\">#{ref}</a> #{ref_type} " \
            "by #{user_name} failed in #{duration} second(s)")
        end
      end

      context 'for succeeded' do
        before do
          pipeline.succeed
        end

        it "calls Hipchat API" do
          hipchat.notify_only_broken_pipelines = false
          hipchat.execute(data)
          expect(WebMock).to have_requested(:post, api_url).once
        end

        it "notifies only broken" do
          hipchat.notify_only_broken_pipelines = true
          hipchat.execute(data)
          expect(WebMock).not_to have_requested(:post, api_url).once
        end
      end
    end

    context "#message_options" do
      it "is set to the defaults" do
        expect(hipchat.__send__(:message_options)).to eq({ notify: false, color: 'yellow' })
      end

      it "sets notify to true" do
        allow(hipchat).to receive(:notify).and_return('1')

        expect(hipchat.__send__(:message_options)).to eq({ notify: true, color: 'yellow' })
      end

      it "sets the color" do
        allow(hipchat).to receive(:color).and_return('red')

        expect(hipchat.__send__(:message_options)).to eq({ notify: false, color: 'red' })
      end

      context 'with a successful build' do
        it 'uses the green color' do
          data = { object_kind: 'pipeline',
                   object_attributes: { status: 'success' } }

          expect(hipchat.__send__(:message_options, data)).to eq({ notify: false, color: 'green' })
        end
      end

      context 'with a failed build' do
        it 'uses the red color' do
          data = { object_kind: 'pipeline',
                   object_attributes: { status: 'failed' } }

          expect(hipchat.__send__(:message_options, data)).to eq({ notify: false, color: 'red' })
        end
      end
    end
  end
end
