# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitPresenter, feature_category: :source_code_management do
  let(:commit) { project.commit }
  let(:presenter) { described_class.new(commit, current_user: user) }

  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { create(:project, :repository) }

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{project.full_path}/-/commit/#{commit.sha}") }
  end

  describe '#detailed_status_for' do
    using RSpec::Parameterized::TableSyntax

    let(:pipeline) { create(:ci_pipeline, :success, project: project, sha: commit.sha, ref: 'ref') }

    subject { presenter.detailed_status_for('ref')&.text }

    where(:read_commit_status, :read_pipeline, :expected_result) do
      true  | true  | 'Passed'
      true  | false | nil
      false | true  | nil
      false | false | nil
    end

    with_them do
      before do
        allow(presenter).to receive(:can?).with(user, :read_commit_status, project).and_return(read_commit_status)
        allow(presenter).to receive(:can?).with(user, :read_pipeline, pipeline).and_return(read_pipeline)
      end

      it { is_expected.to eq expected_result }
    end
  end

  describe '#status_for' do
    using RSpec::Parameterized::TableSyntax

    let(:pipeline) { create(:ci_pipeline, :success, project: project, sha: commit.sha) }

    subject { presenter.status_for }

    where(:read_commit_status, :read_pipeline, :expected_result) do
      true  | true  | 'success'
      true  | false | nil
      false | true  | nil
      false | false | nil
    end

    with_them do
      before do
        allow(presenter).to receive(:can?).with(user, :read_commit_status, project).and_return(read_commit_status)
        allow(presenter).to receive(:can?).with(user, :read_pipeline, pipeline).and_return(read_pipeline)
      end

      it { is_expected.to eq expected_result }
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

  describe '#tags_for_display' do
    subject { presenter.tags_for_display }

    let(:stubbed_tags) { %w[refs/tags/v1.0 refs/tags/v1.1] }

    it 'removes the refs prefix from tags' do
      allow(commit).to receive(:referenced_by).and_return(stubbed_tags)
      expect(subject).to eq(%w[v1.0 v1.1])
    end
  end
end
