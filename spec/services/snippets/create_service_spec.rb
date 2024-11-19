# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::CreateService, feature_category: :source_code_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create(:user, :admin) }

    let(:action) { :create }
    let(:opts) { base_opts.merge(extra_opts) }
    let(:base_opts) do
      {
        title: 'Test snippet',
        file_name: 'snippet.rb',
        content: 'puts "hello world"',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }
    end

    let(:extra_opts) { {} }
    let(:creator) { admin }

    subject { described_class.new(project: project, current_user: creator, params: opts).execute }

    let(:snippet) { subject.payload[:snippet] }

    shared_examples 'a service that creates a snippet' do
      it 'creates a snippet with the provided attributes' do
        expect(snippet.title).to eq(opts[:title])
        expect(snippet.file_name).to eq(opts[:file_name])
        expect(snippet.content).to eq(opts[:content])
        expect(snippet.visibility_level).to eq(opts[:visibility_level])
      end
    end

    shared_examples 'public visibility level restrictions apply' do
      let(:extra_opts) { { visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when user is not an admin' do
        let(:creator) { user }

        it 'responds with an error' do
          expect(subject).to be_error
        end

        it 'does not create a public snippet' do
          expect(subject.message).to match('has been restricted')
        end
      end

      context 'when user is an admin' do
        it 'responds with success' do
          expect(subject).to be_success
        end

        it 'creates a public snippet' do
          expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end

      describe 'when visibility level is passed as a string' do
        let(:extra_opts) { { visibility: 'internal' } }

        before do
          base_opts.delete(:visibility_level)
        end

        it 'assigns the correct visibility level' do
          expect(subject).to be_success
          expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        end
      end
    end

    shared_examples 'snippet create data is tracked' do
      let(:event) { 'create_snippet' }
      let(:category) { 'Snippets::CreateService' }
      let(:user) { admin }

      it_behaves_like 'internal event tracking'

      context 'when create fails' do
        let(:opts) { {} }

        it_behaves_like 'internal event not tracked'
      end
    end

    shared_examples 'an error service response when save fails' do
      let(:extra_opts) { { content: nil } }

      it 'responds with an error' do
        expect(subject).to be_error
      end

      it 'does not create the snippet' do
        expect { subject }.not_to change { Snippet.count }
      end
    end

    shared_examples 'creates repository and files' do
      it 'creates repository' do
        subject

        expect(snippet.repository.exists?).to be_truthy
      end

      it 'commits the files to the repository' do
        subject

        blob = snippet.repository.blob_at('master', base_opts[:file_name])

        expect(blob.data).to eq base_opts[:content]
      end

      it 'passes along correct commit attributes' do
        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:commit_files).with(anything, a_hash_including(skip_target_sha: true))
        end

        subject
      end

      context 'when repository creation action fails' do
        before do
          allow_next_instance_of(Snippet) do |instance|
            allow(instance).to receive(:create_repository).and_return(nil)
          end
        end

        it 'does not create the snippet' do
          expect { subject }.not_to change { Snippet.count }
        end

        it 'returns a generic creation error' do
          expect(snippet.errors[:repository]).to eq ['Error creating the snippet - Repository could not be created']
        end

        it 'does not return a snippet with an id' do
          expect(snippet.id).to be_nil
        end
      end

      context 'when repository creation fails with invalid file name' do
        let(:extra_opts) { { file_name: 'invalid://file/name/here' } }

        it 'returns an appropriate error' do
          expect(snippet.errors[:repository]).to eq ['Error creating the snippet - Invalid file name']
        end
      end

      context 'when the commit action fails' do
        let(:error) { SnippetRepository::CommitError.new('foobar') }

        before do
          allow_next_instance_of(SnippetRepository) do |instance|
            allow(instance).to receive(:multi_files_action).and_raise(error)
          end
        end

        it 'does not create the snippet' do
          expect { subject }.not_to change { Snippet.count }
        end

        it 'destroys the created repository' do
          expect_next_instance_of(Repository) do |instance|
            expect(instance).to receive(:remove).and_call_original
          end

          subject
        end

        it 'destroys the snippet_repository' do
          subject

          expect(SnippetRepository.count).to be_zero
        end

        it 'logs the error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(error, service: 'Snippets::CreateService')

          subject
        end

        it 'returns a generic error' do
          expect(subject).to be_error
          expect(snippet.errors[:repository]).to eq ['Error creating the snippet']
        end
      end

      context 'when snippet creation fails' do
        let(:extra_opts) { { content: nil } }

        it 'does not create repository' do
          expect do
            subject
          end.not_to change(Snippet, :count)

          expect(snippet.repository_exists?).to be_falsey
        end
      end
    end

    shared_examples 'after_save callback to store_mentions' do |mentionable_class|
      context 'when mentionable attributes change' do
        let(:extra_opts) { { description: "Description with #{user.to_reference}" } }

        it 'saves mentions' do
          expect_next_instance_of(mentionable_class) do |instance|
            expect(instance).to receive(:store_mentions!).and_call_original
          end
          expect(snippet.user_mentions.count).to eq 1
        end
      end

      context 'when mentionable attributes do not change' do
        it 'does not call store_mentions' do
          expect_next_instance_of(mentionable_class) do |instance|
            expect(instance).not_to receive(:store_mentions!)
          end
          expect(snippet.user_mentions.count).to eq 0
        end
      end

      context 'when save fails' do
        it 'does not call store_mentions' do
          base_opts.delete(:title)

          expect_next_instance_of(mentionable_class) do |instance|
            expect(instance).not_to receive(:store_mentions!)
          end
          expect(snippet.valid?).to be false
        end
      end
    end

    shared_examples 'when snippet_actions param is present' do
      let(:file_path) { 'snippet_file_path.rb' }
      let(:content) { 'snippet_content' }
      let(:snippet_actions) { [{ action: 'create', file_path: file_path, content: content }] }
      let(:base_opts) do
        {
          title: 'Test snippet',
          visibility_level: Gitlab::VisibilityLevel::PRIVATE,
          snippet_actions: snippet_actions
        }
      end

      it 'creates a snippet with the provided attributes' do
        expect(snippet.title).to eq(opts[:title])
        expect(snippet.visibility_level).to eq(opts[:visibility_level])
        expect(snippet.file_name).to eq(file_path)
        expect(snippet.content).to eq(content)
      end

      it 'commit the files to the repository' do
        expect(subject).to be_success

        blob = snippet.repository.blob_at('master', file_path)

        expect(blob.data).to eq content
      end

      context 'when content or file_name params are present' do
        let(:extra_opts) { { content: 'foo', file_name: 'path' } }

        it 'a validation error is raised' do
          expect(subject).to be_error
          expect(snippet.errors.full_messages_for(:content)).to eq ['Content and snippet files cannot be used together']
          expect(snippet.errors.full_messages_for(:file_name)).to eq ['File name and snippet files cannot be used together']
          expect(snippet.repository.exists?).to be_falsey
        end
      end

      context 'when snippet_actions param is invalid' do
        let(:snippet_actions) { [{ action: 'invalid_action', file_path: 'snippet_file_path.rb', content: 'snippet_content' }] }

        it 'a validation error is raised' do
          expect(subject).to be_error
          expect(snippet.errors.full_messages_for(:snippet_actions)).to eq ['Snippet actions have invalid data']
          expect(snippet.repository.exists?).to be_falsey
        end
      end

      context 'when snippet_actions contain an action different from "create"' do
        let(:snippet_actions) { [{ action: 'delete', file_path: 'snippet_file_path.rb' }] }

        it 'a validation error is raised' do
          expect(subject).to be_error
          expect(snippet.errors.full_messages_for(:snippet_actions)).to eq ['Snippet actions have invalid data']
          expect(snippet.repository.exists?).to be_falsey
        end
      end

      context 'when "create" operation does not have file_path or is empty' do
        let(:snippet_actions) { [{ action: 'create', content: content }, { action: 'create', content: content, file_path: '' }] }

        it 'generates the file path for the files' do
          expect(subject).to be_success
          expect(snippet.repository.blob_at('master', 'snippetfile1.txt').data).to eq content
          expect(snippet.repository.blob_at('master', 'snippetfile2.txt').data).to eq content
        end
      end
    end

    context 'when ProjectSnippet' do
      let_it_be(:project) { create(:project) }

      before do
        project.add_developer(user)
      end

      it_behaves_like 'a service that creates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'checking spam'
      it_behaves_like 'snippet create data is tracked'
      it_behaves_like 'an error service response when save fails'
      it_behaves_like 'creates repository and files'
      it_behaves_like 'after_save callback to store_mentions', ProjectSnippet
      it_behaves_like 'when snippet_actions param is present'
      it_behaves_like 'invalid params error response'

      context 'when uploaded files are passed to the service' do
        let(:extra_opts) { { files: ['foo'] } }

        it 'does not move uploaded files to the snippet' do
          expect_next_instance_of(described_class) do |instance|
            expect(instance).to receive(:move_temporary_files).and_call_original
          end

          expect_any_instance_of(FileMover).not_to receive(:execute)

          subject
        end
      end

      context 'when Current.organization is set', :with_current_organization do
        let(:extra_opts) { { organization_id: current_organization.id } }

        it 'sets the organization_id to nil' do
          expect(snippet.organization_id).to be_nil
        end
      end

      context 'when Current.organization is not set' do
        it 'sets the organization_id to nil' do
          expect(snippet.organization_id).to be_nil
        end
      end
    end

    context 'when PersonalSnippet' do
      let(:project) { nil }

      it_behaves_like 'a service that creates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'checking spam'
      it_behaves_like 'snippet create data is tracked'
      it_behaves_like 'an error service response when save fails'
      it_behaves_like 'creates repository and files'
      it_behaves_like 'after_save callback to store_mentions', PersonalSnippet
      it_behaves_like 'when snippet_actions param is present'
      it_behaves_like 'invalid params error response'

      context 'when Current.organization is set', :with_current_organization do
        let(:extra_opts) { { organization_id: current_organization.id } }

        it 'sets the organization_id to the current organization' do
          expect(snippet.organization_id).to eq(current_organization.id)
        end

        it 'does not set organization_id to the default organization' do
          expect(snippet.organization_id)
            .not_to eq(Organizations::Organization::DEFAULT_ORGANIZATION_ID)
        end
      end

      context 'when Current.organization is not set' do
        it 'still uses the default organization_id' do
          expect(snippet.organization_id)
            .to eq(Organizations::Organization::DEFAULT_ORGANIZATION_ID)
        end
      end

      context 'when the snippet description contains files' do
        include FileMoverHelpers

        let(:title) { 'Title' }
        let(:picture_secret) { SecureRandom.hex }
        let(:text_secret) { SecureRandom.hex }
        let(:picture_file) { "/-/system/user/#{creator.id}/#{picture_secret}/picture.jpg" }
        let(:text_file) { "/-/system/user/#{creator.id}/#{text_secret}/text.txt" }
        let(:files) { [picture_file, text_file] }
        let(:description) do
          "Description with picture: ![picture](/uploads#{picture_file}) and "\
          "text: [text.txt](/uploads#{text_file})"
        end

        before do
          allow(FileUtils).to receive(:mkdir_p)
          allow(FileUtils).to receive(:move)
        end

        let(:extra_opts) { { description: description, title: title, files: files } }

        it 'stores the snippet description correctly' do
          stub_file_mover(text_file)
          stub_file_mover(picture_file)

          snippet = subject.payload[:snippet]

          expected_description = "Description with picture: "\
            "![picture](/uploads/-/system/personal_snippet/#{snippet.id}/#{picture_secret}/picture.jpg) and "\
            "text: [text.txt](/uploads/-/system/personal_snippet/#{snippet.id}/#{text_secret}/text.txt)"

          expect(snippet.description).to eq(expected_description)
        end

        context 'when there is a validation error' do
          let(:title) { nil }

          it 'does not move uploaded files to the snippet' do
            expect_any_instance_of(described_class).not_to receive(:move_temporary_files)

            subject
          end
        end
      end
    end
  end
end
