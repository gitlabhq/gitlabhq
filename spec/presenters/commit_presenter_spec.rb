# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitPresenter do
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit }
  let(:user) { create(:user) }
  let(:presenter) { described_class.new(commit, current_user: user) }

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{project.full_path}/-/commit/#{commit.sha}") }
  end

  describe '#status_for' do
    subject { presenter.status_for('ref') }

    context 'when user can read_commit_status' do
      before do
        allow(presenter).to receive(:can?).with(user, :read_commit_status, project).and_return(true)
      end

      it 'returns commit status for ref' do
        pipeline = double
        status = double

        expect(commit).to receive(:latest_pipeline).with('ref').and_return(pipeline)
        expect(pipeline).to receive(:detailed_status).with(user).and_return(status)

        expect(subject).to eq(status)
      end
    end

    context 'when user can not read_commit_status' do
      it 'is nil' do
        is_expected.to eq(nil)
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

  describe '#signature_html' do
    let(:signature) { 'signature' }

    before do
      expect(commit).to receive(:has_signature?).and_return(true)
      allow(ApplicationController.renderer).to receive(:render).and_return(signature)
    end

    it 'renders html for displaying signature' do
      expect(presenter.signature_html).to eq(signature)
    end
  end
end
