# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::GitPostReceive do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:identifier) { "key-#{project.id}" }

  subject { described_class.new(project, identifier, changes.dup, {}) }

  describe '#identify?' do
    context 'when identifier is a deploy key' do
      let_it_be(:deploy_key) { create(:deploy_key, user: project.first_owner) }
      let_it_be(:identifier) { "key-#{deploy_key.id}" }
      let(:changes) do
        <<~EOF
          654322 210986 refs/tags/test1
        EOF
      end

      it 'returns false' do
        expect(subject.identify).to eq(project.first_owner)
      end
    end
  end

  describe '#includes_branches?' do
    context 'with no branches' do
      let(:changes) do
        <<~EOF
          654321 210987 refs/nobranches/tag1
          654322 210986 refs/tags/test1
          654323 210985 refs/merge-requests/mr1
        EOF
      end

      it 'returns false' do
        expect(subject.includes_branches?).to be_falsey
      end
    end

    context 'with branches' do
      let(:changes) do
        <<~EOF
          654322 210986 refs/heads/test1
          654321 210987 refs/tags/tag1
          654323 210985 refs/merge-requests/mr1
        EOF
      end

      it 'returns true' do
        expect(subject.includes_branches?).to be_truthy
      end
    end

    context 'with malformed changes' do
      let(:changes) do
        <<~EOF
          ref/heads/1 a
          somebranch refs/heads/2
        EOF
      end

      it 'returns false' do
        expect(subject.includes_branches?).to be_falsey
      end
    end
  end

  describe '#includes_tags?' do
    context 'with no tags' do
      let(:changes) do
        <<~EOF
          654321 210987 refs/notags/tag1
          654322 210986 refs/heads/test1
          654323 210985 refs/merge-requests/mr1
        EOF
      end

      it 'returns false' do
        expect(subject.includes_tags?).to be_falsey
      end
    end

    context 'with tags' do
      let(:changes) do
        <<~EOF
          654322 210986 refs/heads/test1
          654321 210987 refs/tags/tag1
          654323 210985 refs/merge-requests/mr1
        EOF
      end

      it 'returns true' do
        expect(subject.includes_tags?).to be_truthy
      end
    end

    context 'with malformed changes' do
      let(:changes) do
        <<~EOF
          ref/tags/1 a
          sometag refs/tags/2
        EOF
      end

      it 'returns false' do
        expect(subject.includes_tags?).to be_falsey
      end
    end
  end

  describe '#includes_default_branch?' do
    context 'with no default branch' do
      let(:changes) do
        <<~EOF
          654321 210987 refs/heads/test1
          654322 210986 refs/tags/#{project.default_branch}
          654323 210985 refs/heads/test3
        EOF
      end

      it 'returns false' do
        expect(subject.includes_default_branch?).to be_falsey
      end
    end

    context 'with a project with no default branch' do
      let(:changes) do
        <<~EOF
          654321 210987 refs/heads/test1
        EOF
      end

      it 'returns true' do
        expect(project).to receive(:default_branch).and_return(nil)
        expect(subject.includes_default_branch?).to be_truthy
      end
    end

    context 'with default branch' do
      let(:changes) do
        <<~EOF
          654322 210986 refs/heads/test1
          654321 210987 refs/tags/test2
          654323 210985 refs/heads/#{project.default_branch}
        EOF
      end

      it 'returns true' do
        expect(subject.includes_default_branch?).to be_truthy
      end
    end
  end
end
