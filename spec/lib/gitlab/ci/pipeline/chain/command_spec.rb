# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Command do
  let_it_be(:project) { create(:project, :repository) }

  describe '#initialize' do
    subject do
      described_class.new(origin_ref: 'master')
    end

    it 'properly initialises object from hash' do
      expect(subject.origin_ref).to eq('master')
    end
  end

  context 'handling of origin_ref' do
    let(:command) { described_class.new(project: project, origin_ref: origin_ref) }

    describe '#branch_exists?' do
      subject { command.branch_exists? }

      context 'for existing branch' do
        let(:origin_ref) { 'master' }

        it { is_expected.to eq(true) }
      end

      context 'for invalid branch' do
        let(:origin_ref) { 'something' }

        it { is_expected.to eq(false) }
      end
    end

    describe '#tag_exists?' do
      subject { command.tag_exists? }

      context 'for existing ref' do
        let(:origin_ref) { 'v1.0.0' }

        it { is_expected.to eq(true) }
      end

      context 'for invalid ref' do
        let(:origin_ref) { 'something' }

        it { is_expected.to eq(false) }
      end
    end

    describe '#merge_request_ref_exists?' do
      subject { command.merge_request_ref_exists? }

      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      context 'for existing merge request ref' do
        let(:origin_ref) { merge_request.ref_path }

        it { is_expected.to eq(true) }
      end

      context 'for branch ref' do
        let(:origin_ref) { merge_request.source_branch }

        it { is_expected.to eq(false) }
      end
    end

    describe '#ref' do
      subject { command.ref }

      context 'for regular ref' do
        let(:origin_ref) { 'master' }

        it { is_expected.to eq('master') }
      end

      context 'for branch ref' do
        let(:origin_ref) { 'refs/heads/master' }

        it { is_expected.to eq('master') }
      end

      context 'for tag ref' do
        let(:origin_ref) { 'refs/tags/1.0.0' }

        it { is_expected.to eq('1.0.0') }
      end

      context 'for other refs' do
        let(:origin_ref) { 'refs/merge-requests/11/head' }

        it { is_expected.to eq('refs/merge-requests/11/head') }
      end
    end
  end

  describe '#sha' do
    subject { command.sha }

    context 'when invalid checkout_sha is specified' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa') }

      it 'returns empty value' do
        is_expected.to be_nil
      end
    end

    context 'when a valid checkout_sha is specified' do
      let(:command) { described_class.new(project: project, checkout_sha: project.commit.id) }

      it 'returns checkout_sha' do
        is_expected.to eq(project.commit.id)
      end
    end

    context 'when a valid after_sha is specified' do
      let(:command) { described_class.new(project: project, after_sha: project.commit.id) }

      it 'returns after_sha' do
        is_expected.to eq(project.commit.id)
      end
    end

    context 'when a valid origin_ref is specified' do
      let(:command) { described_class.new(project: project, origin_ref: 'HEAD') }

      it 'returns SHA for given ref' do
        is_expected.to eq(project.commit.id)
      end
    end
  end

  describe '#origin_sha' do
    subject { command.origin_sha }

    context 'when using checkout_sha and after_sha' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa', after_sha: 'bbb') }

      it 'uses checkout_sha' do
        is_expected.to eq('aaa')
      end
    end

    context 'when using after_sha only' do
      let(:command) { described_class.new(project: project, after_sha: 'bbb') }

      it 'uses after_sha' do
        is_expected.to eq('bbb')
      end
    end
  end

  describe '#before_sha' do
    subject { command.before_sha }

    context 'when using checkout_sha and before_sha' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa', before_sha: 'bbb') }

      it 'uses before_sha' do
        is_expected.to eq('bbb')
      end
    end

    context 'when using checkout_sha only' do
      let(:command) { described_class.new(project: project, checkout_sha: 'aaa') }

      it 'uses checkout_sha' do
        is_expected.to eq('aaa')
      end
    end

    context 'when checkout_sha and before_sha are empty' do
      let(:command) { described_class.new(project: project) }

      it 'uses BLANK_SHA' do
        is_expected.to eq(Gitlab::Git::BLANK_SHA)
      end
    end
  end

  describe '#source_sha' do
    subject { command.source_sha }

    let(:command) do
      described_class.new(project: project,
                          source_sha: source_sha,
                          merge_request: merge_request)
    end

    let(:merge_request) do
      create(:merge_request, target_project: project, source_project: project)
    end

    let(:source_sha) { nil }

    context 'when source_sha is specified' do
      let(:source_sha) { 'abc' }

      it 'returns the specified value' do
        is_expected.to eq('abc')
      end
    end
  end

  describe '#target_sha' do
    subject { command.target_sha }

    let(:command) do
      described_class.new(project: project,
                          target_sha: target_sha,
                          merge_request: merge_request)
    end

    let(:merge_request) do
      create(:merge_request, target_project: project, source_project: project)
    end

    let(:target_sha) { nil }

    context 'when target_sha is specified' do
      let(:target_sha) { 'abc' }

      it 'returns the specified value' do
        is_expected.to eq('abc')
      end
    end
  end

  describe '#protected_ref?' do
    let(:command) { described_class.new(project: project, origin_ref: 'my-branch') }

    subject { command.protected_ref? }

    context 'when a ref is protected' do
      before do
        expect_any_instance_of(Project).to receive(:protected_for?).with('my-branch').and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when a ref is unprotected' do
      before do
        expect_any_instance_of(Project).to receive(:protected_for?).with('my-branch').and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#ambiguous_ref' do
    let(:project) { create(:project, :repository) }
    let(:command) { described_class.new(project: project, origin_ref: 'ref') }

    subject { command.ambiguous_ref? }

    context 'when ref is not ambiguous' do
      it { is_expected. to eq(false) }
    end

    context 'when ref is ambiguous' do
      before do
        project.repository.add_tag(project.creator, 'ref', 'master')
        project.repository.add_branch(project.creator, 'ref', 'master')
      end

      it { is_expected. to eq(true) }
    end
  end

  describe '#dangling_build?' do
    let(:project) { create(:project, :repository) }
    let(:command) { described_class.new(project: project, source: source) }

    subject { command.dangling_build? }

    context 'when source is :webide' do
      let(:source) { :webide }

      it { is_expected.to eq(true) }
    end

    context 'when source is :ondemand_dast_scan' do
      let(:source) { :ondemand_dast_scan }

      it { is_expected.to eq(true) }
    end

    context 'when source something else' do
      let(:source) { :web }

      it { is_expected.to eq(false) }
    end
  end

  describe '#creates_child_pipeline?' do
    let(:command) { described_class.new(bridge: bridge) }

    subject { command.creates_child_pipeline? }

    context 'when bridge is present' do
      context 'when bridge triggers a child pipeline' do
        let(:bridge) { double(:bridge, triggers_child_pipeline?: true) }

        it { is_expected.to be_truthy }
      end

      context 'when bridge triggers a multi-project pipeline' do
        let(:bridge) { double(:bridge, triggers_child_pipeline?: false) }

        it { is_expected.to be_falsey }
      end
    end

    context 'when bridge is not present' do
      let(:bridge) { nil }

      it { is_expected.to be_falsey }
    end
  end

  describe '#increment_pipeline_failure_reason_counter' do
    let(:command) { described_class.new }
    let(:reason) { :size_limit_exceeded }

    subject { command.increment_pipeline_failure_reason_counter(reason) }

    it 'increments the error metric' do
      counter = Gitlab::Metrics.counter(:gitlab_ci_pipeline_failure_reasons, 'desc')
      expect { subject }.to change { counter.get(reason: reason.to_s) }.by(1)
    end

    context 'when the reason is nil' do
      let(:reason) { nil }

      it 'increments the error metric with unknown_failure' do
        counter = Gitlab::Metrics.counter(:gitlab_ci_pipeline_failure_reasons, 'desc')
        expect { subject }.to change { counter.get(reason: 'unknown_failure') }.by(1)
      end
    end
  end
end
