# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetPresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:user) { create(:user) }
  let_it_be(:personal_snippet) { create(:personal_snippet, author: user) }
  let_it_be(:project_snippet) { create(:project_snippet, author: user) }

  let(:project) { project_snippet.project }
  let(:presenter) { described_class.new(snippet, current_user: user) }

  before do
    project.add_developer(user)
  end

  describe '#web_url' do
    subject { presenter.web_url }

    context 'with PersonalSnippet' do
      let(:snippet) { personal_snippet }

      it 'returns snippet web url' do
        expect(subject).to match "/-/snippets/#{snippet.id}"
      end
    end

    context 'with ProjectSnippet' do
      let(:snippet) { project_snippet }

      it 'returns snippet web url' do
        expect(subject).to match "/#{project.full_path}/-/snippets/#{snippet.id}"
      end
    end
  end

  describe '#raw_url' do
    subject { presenter.raw_url }

    context 'with PersonalSnippet' do
      let(:snippet) { personal_snippet }

      it 'returns snippet web url' do
        expect(subject).to match "/-/snippets/#{snippet.id}/raw"
      end
    end

    context 'with ProjectSnippet' do
      let(:snippet) { project_snippet }

      it 'returns snippet web url' do
        expect(subject).to match "/#{project.full_path}/-/snippets/#{snippet.id}/raw"
      end
    end
  end

  describe '#can_read_snippet?' do
    subject { presenter.can_read_snippet? }

    context 'with PersonalSnippet' do
      let(:snippet) { personal_snippet }

      it 'checks read_snippet' do
        expect(presenter).to receive(:can?).with(user, :read_snippet, snippet)

        subject
      end
    end

    context 'with ProjectSnippet' do
      let(:snippet) { project_snippet }

      it 'checks read_snippet' do
        expect(presenter).to receive(:can?).with(user, :read_snippet, snippet)

        subject
      end
    end
  end

  describe '#can_update_snippet?' do
    subject { presenter.can_update_snippet? }

    context 'with PersonalSnippet' do
      let(:snippet) { personal_snippet }

      it 'checks update_snippet' do
        expect(presenter).to receive(:can?).with(user, :update_snippet, snippet)

        subject
      end
    end

    context 'with ProjectSnippet' do
      let(:snippet) { project_snippet }

      it 'checks update_snippet' do
        expect(presenter).to receive(:can?).with(user, :update_snippet, snippet)

        subject
      end
    end
  end

  describe '#can_admin_snippet?' do
    subject { presenter.can_admin_snippet? }

    context 'with PersonalSnippet' do
      let(:snippet) { personal_snippet }

      it 'checks admin_snippet' do
        expect(presenter).to receive(:can?).with(user, :admin_snippet, snippet)

        subject
      end
    end

    context 'with ProjectSnippet' do
      let(:snippet) { project_snippet }

      it 'checks admin_snippet' do
        expect(presenter).to receive(:can?).with(user, :admin_snippet, snippet)

        subject
      end
    end
  end

  describe '#can_report_as_spam' do
    let(:snippet) { personal_snippet }

    subject { presenter.can_report_as_spam? }

    it 'returns false if the user cannot submit the snippet as spam' do
      expect(subject).to be_falsey
    end

    it 'returns true if the user can submit the snippet as spam' do
      allow(snippet).to receive(:submittable_as_spam_by?).and_return(true)

      expect(subject).to be_truthy
    end
  end

  describe '#blob' do
    let(:snippet) { personal_snippet }

    subject { presenter.blob }

    context 'when snippet does not have a repository' do
      it 'returns SnippetBlob' do
        expect(subject).to eq snippet.blob
      end
    end

    context 'when snippet has a repository' do
      let(:snippet) { create(:project_snippet, :repository, author: user) }

      it 'returns repository first blob' do
        expect(subject.name).to eq snippet.blobs.first.name
      end
    end
  end
end
