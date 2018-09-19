require 'spec_helper'

describe HangoutsChatService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:webhook) }
      it_behaves_like 'issue tracker service URL attribute', :webhook
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:webhook) }
    end
  end

  describe '#execute' do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:webhook_url) { 'https://example.gitlab.com/' }

    before do
      allow(subject).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    shared_examples 'Hangouts Chat service' do
      it 'calls Hangouts Chat API' do
        subject.execute(sample_data)

        expect(WebMock)
          .to have_requested(:post, webhook_url)
          .with { |req| req.body =~ /\A{"text":.+}\Z/ }
          .once
      end
    end

    context 'with push events' do
      let(:sample_data) do
        Gitlab::DataBuilder::Push.build_sample(project, user)
      end

      it_behaves_like 'Hangouts Chat service'

      it 'specifies the webhook when it is configured' do
        expect(HangoutsChat::Sender).to receive(:new).with(webhook_url).and_return(double(:hangouts_chat_service).as_null_object)

        subject.execute(sample_data)
      end

      context 'with not default branch' do
        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project, user, nil, nil, 'not-the-default-branch')
        end

        context 'when notify_only_default_branch enabled' do
          before do
            subject.notify_only_default_branch = true
          end

          it 'does not call the Hangouts Chat API' do
            result = subject.execute(sample_data)

            expect(result).to be_falsy
          end
        end

        context 'when notify_only_default_branch disabled' do
          before do
            subject.notify_only_default_branch = false
          end

          it_behaves_like 'Hangouts Chat service'
        end
      end
    end

    context 'with issue events' do
      let(:opts) { { title: 'Awesome issue', description: 'please fix' } }
      let(:sample_data) do
        service = Issues::CreateService.new(project, user, opts)
        issue = service.execute
        service.hook_data(issue, 'open')
      end

      it_behaves_like 'Hangouts Chat service'
    end

    context 'with merge events' do
      let(:opts) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master'
        }
      end

      let(:sample_data) do
        service = MergeRequests::CreateService.new(project, user, opts)
        merge_request = service.execute
        service.hook_data(merge_request, 'open')
      end

      before do
        project.add_developer(user)
      end

      it_behaves_like 'Hangouts Chat service'
    end

    context 'with wiki page events' do
      let(:opts) do
        {
          title: 'Awesome wiki_page',
          content: 'Some text describing some thing or another',
          format: 'md',
          message: 'user created page: Awesome wiki_page'
        }
      end
      let(:wiki_page) { create(:wiki_page, wiki: project.wiki, attrs: opts) }
      let(:sample_data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, 'create') }

      it_behaves_like 'Hangouts Chat service'
    end

    context 'with note events' do
      let(:sample_data) { Gitlab::DataBuilder::Note.build(note, user) }

      context 'with commit comment' do
        let(:note) do
          create(:note_on_commit, author: user,
                                  project: project,
                                  commit_id: project.repository.commit.id,
                                  note: 'a comment on a commit')
        end

        it_behaves_like 'Hangouts Chat service'
      end

      context 'with merge request comment' do
        let(:note) do
          create(:note_on_merge_request, project: project,
                                         note: 'merge request note')
        end

        it_behaves_like 'Hangouts Chat service'
      end

      context 'with issue comment' do
        let(:note) do
          create(:note_on_issue, project: project, note: 'issue note')
        end

        it_behaves_like 'Hangouts Chat service'
      end

      context 'with snippet comment' do
        let(:note) do
          create(:note_on_project_snippet, project: project,
                                           note: 'snippet note')
        end

        it_behaves_like 'Hangouts Chat service'
      end
    end

    context 'with pipeline events' do
      let(:pipeline) do
        create(:ci_pipeline,
               project: project, status: status,
               sha: project.commit.sha, ref: project.default_branch)
      end
      let(:sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

      context 'with failed pipeline' do
        let(:status) { 'failed' }

        it_behaves_like 'Hangouts Chat service'
      end

      context 'with succeeded pipeline' do
        let(:status) { 'success' }

        context 'with default notify_only_broken_pipelines' do
          it 'does not call Hangouts Chat API' do
            result = subject.execute(sample_data)

            expect(result).to be_falsy
          end
        end

        context 'when notify_only_broken_pipelines is false' do
          before do
            subject.notify_only_broken_pipelines = false
          end

          it_behaves_like 'Hangouts Chat service'
        end
      end

      context 'with not default branch' do
        let(:pipeline) do
          create(:ci_pipeline, project: project, status: 'failed', ref: 'not-the-default-branch')
        end

        context 'when notify_only_default_branch enabled' do
          before do
            subject.notify_only_default_branch = true
          end

          it 'does not call the Hangouts Chat API' do
            result = subject.execute(sample_data)

            expect(result).to be_falsy
          end
        end

        context 'when notify_only_default_branch disabled' do
          before do
            subject.notify_only_default_branch = false
          end

          it_behaves_like 'Hangouts Chat service'
        end
      end
    end
  end
end
