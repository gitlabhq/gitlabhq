# frozen_string_literal: true

require 'spec_helper'

describe Snippets::UpdateService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create :user, admin: true }
    let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
    let(:options) do
      {
        title: 'Test snippet',
        file_name: 'snippet.rb',
        content: 'puts "hello world"',
        visibility_level: visibility_level
      }
    end
    let(:updater) { user }

    subject do
      Snippets::UpdateService.new(
        project,
        updater,
        options
      ).execute(snippet)
    end

    shared_examples 'a service that updates a snippet' do
      it 'updates a snippet with the provided attributes' do
        expect { subject }.to change { snippet.title }.from(snippet.title).to(options[:title])
          .and change { snippet.file_name }.from(snippet.file_name).to(options[:file_name])
          .and change { snippet.content }.from(snippet.content).to(options[:content])
      end
    end

    shared_examples 'public visibility level restrictions apply' do
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'when user is not an admin' do
        it 'responds with an error' do
          expect(subject).to be_error
        end

        it 'does not update snippet to public visibility' do
          original_visibility = snippet.visibility_level

          expect(subject.message).to match('has been restricted')
          expect(snippet.visibility_level).to eq(original_visibility)
        end
      end

      context 'when user is an admin' do
        let(:updater) { admin }

        it 'responds with success' do
          expect(subject).to be_success
        end

        it 'updates the snippet to public visibility' do
          old_visibility = snippet.visibility_level

          expect(subject.payload[:snippet]).not_to be_nil
          expect(snippet.visibility_level).not_to eq(old_visibility)
          expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
        end
      end

      context 'when visibility level is passed as a string' do
        before do
          options[:visibility] = 'internal'
          options.delete(:visibility_level)
        end

        it 'assigns the correct visibility level' do
          expect(subject).to be_success
          expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        end
      end
    end

    shared_examples 'snippet update data is tracked' do
      let(:counter) { Gitlab::UsageDataCounters::SnippetCounter }

      it 'increments count when create succeeds' do
        expect { subject }.to change { counter.read(:update) }.by 1
      end

      context 'when update fails' do
        let(:options) { { title: '' } }

        it 'does not increment count' do
          expect { subject }.not_to change { counter.read(:update) }
        end
      end
    end

    context 'when Project Snippet' do
      let_it_be(:project) { create(:project) }
      let!(:snippet) { create(:project_snippet, author: user, project: project) }

      before do
        project.add_developer(user)
      end

      it_behaves_like 'a service that updates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'snippet update data is tracked'
    end

    context 'when PersonalSnippet' do
      let(:project) { nil }
      let!(:snippet) { create(:personal_snippet, author: user) }

      it_behaves_like 'a service that updates a snippet'
      it_behaves_like 'public visibility level restrictions apply'
      it_behaves_like 'snippet update data is tracked'
    end
  end
end
