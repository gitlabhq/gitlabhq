# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::GitPostReceive do
  let(:project) { create(:project) }

  subject { described_class.new(project, "project-#{project.id}", changes.dup, {}) }

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
end
