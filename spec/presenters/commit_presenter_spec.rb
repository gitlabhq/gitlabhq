# frozen_string_literal: true

require 'spec_helper'

describe CommitPresenter do
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit }
  let(:user) { create(:user) }
  let(:presenter) { described_class.new(commit, current_user: user) }

  describe '#status_for' do
    subject { presenter.status_for('ref') }

    context 'when user can read_commit_status' do
      before do
        allow(presenter).to receive(:can?).with(user, :read_commit_status, project).and_return(true)
      end

      it 'returns commit status for ref' do
        expect(commit).to receive(:status).with('ref').and_return('test')

        expect(subject).to eq('test')
      end
    end

    context 'when user can not read_commit_status' do
      it 'is false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#any_pipelines?' do
    subject { presenter.any_pipelines? }

    context 'when user can read pipeline' do
      before do
        allow(presenter).to receive(:can?).with(user, :read_pipeline, project).and_return(true)
      end

      it 'returns if there are any pipelines for commit' do
        expect(commit).to receive_message_chain(:pipelines, :any?).and_return(true)

        expect(subject).to eq(true)
      end
    end

    context 'when user can not read pipeline' do
      it 'is false' do
        is_expected.to eq(false)
      end
    end
  end
end
