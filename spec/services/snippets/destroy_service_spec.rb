# frozen_string_literal: true

require 'spec_helper'

describe Snippets::DestroyService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  describe '#execute' do
    subject { Snippets::DestroyService.new(user, snippet).execute }

    context 'when snippet is nil' do
      let(:snippet) { nil }

      it 'returns a ServiceResponse error' do
        expect(subject).to be_error
      end
    end

    shared_examples 'a successful destroy' do
      it 'deletes the snippet' do
        expect { subject }.to change { Snippet.count }.by(-1)
      end

      it 'returns ServiceResponse success' do
        expect(subject).to be_success
      end
    end

    shared_examples 'an unsuccessful destroy' do
      it 'does not delete the snippet' do
        expect { subject }.to change { Snippet.count }.by(0)
      end

      it 'returns ServiceResponse error' do
        expect(subject).to be_error
      end
    end

    context 'when ProjectSnippet' do
      let!(:snippet) { create(:project_snippet, project: project, author: author) }

      context 'when user is able to admin_project_snippet' do
        let(:author) { user }

        before do
          project.add_developer(user)
        end

        it_behaves_like 'a successful destroy'
      end

      context 'when user is not able to admin_project_snippet' do
        let(:author) { other_user }

        it_behaves_like 'an unsuccessful destroy'
      end
    end

    context 'when PersonalSnippet' do
      let!(:snippet) { create(:personal_snippet, author: author) }

      context 'when user is able to admin_personal_snippet' do
        let(:author) { user }

        it_behaves_like 'a successful destroy'
      end

      context 'when user is not able to admin_personal_snippet' do
        let(:author) { other_user }

        it_behaves_like 'an unsuccessful destroy'
      end
    end
  end
end
