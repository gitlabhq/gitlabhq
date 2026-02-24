# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::RefResolver, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:resolver) { described_class.new(repository, origin_ref) }

  describe '#resolved_ref' do
    subject { resolver.resolved_ref }

    context 'when ref is a full branch path' do
      let(:origin_ref) { 'refs/heads/master' }

      it { is_expected.to eq('refs/heads/master') }
    end

    context 'when ref is a full tag path' do
      let(:origin_ref) { 'refs/tags/v1.0.0' }

      it { is_expected.to eq('refs/tags/v1.0.0') }
    end

    context 'when ref is a merge request ref' do
      let(:origin_ref) { 'refs/merge-requests/123/merge' }

      it { is_expected.to eq('refs/merge-requests/123/merge') }
    end

    context 'when ref is a workload ref' do
      let(:origin_ref) { 'refs/workloads/abc123' }

      it { is_expected.to eq('refs/workloads/abc123') }
    end

    context 'when ref is a short branch name' do
      let(:origin_ref) { 'master' }

      it { is_expected.to eq('refs/heads/master') }
    end

    context 'when ref is a short tag name' do
      let(:origin_ref) { 'v1.0.0' }

      it { is_expected.to eq('refs/tags/v1.0.0') }
    end

    context 'when ref is ambiguous' do
      let(:origin_ref) { 'ambiguous-ref' }

      before do
        repository.add_branch(project.creator, 'ambiguous-ref', 'master')
        repository.add_tag(project.creator, 'ambiguous-ref', 'master')
      end

      it { is_expected.to be_nil }
    end

    context 'when ref does not exist' do
      let(:origin_ref) { 'nonexistent' }

      it { is_expected.to be_nil }
    end

    context 'when ref is a full branch path that does not exist' do
      let(:origin_ref) { 'refs/heads/nonexistent-branch' }

      it { is_expected.to be_nil }
    end

    context 'when ref is a full tag path that does not exist' do
      let(:origin_ref) { 'refs/tags/nonexistent-tag' }

      it { is_expected.to be_nil }
    end
  end

  describe '#ambiguous?' do
    subject { resolver.ambiguous? }

    context 'when ref exists as both branch and tag' do
      let(:origin_ref) { 'ambiguous-duplicate' }

      before do
        repository.add_branch(project.creator, 'ambiguous-duplicate', 'master')
        repository.add_tag(project.creator, 'ambiguous-duplicate', 'master')
      end

      it { is_expected.to be(true) }
    end

    context 'when ref exists only as branch' do
      let(:origin_ref) { 'master' }

      it { is_expected.to be(false) }
    end

    context 'when ref exists only as tag' do
      let(:origin_ref) { 'v1.0.0' }

      it { is_expected.to be(false) }
    end

    context 'when ref does not exist' do
      let(:origin_ref) { 'nonexistent' }

      it { is_expected.to be(false) }
    end

    context 'when ref is a fully-qualified path but short name is ambiguous' do
      let(:origin_ref) { 'refs/heads/ambiguous-qualified-ref' }

      before do
        repository.add_branch(project.creator, 'ambiguous-qualified-ref', 'master')
        repository.add_tag(project.creator, 'ambiguous-qualified-ref', 'master')
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#branch?' do
    subject { resolver.branch? }

    context 'when ref is a full branch path' do
      let(:origin_ref) { 'refs/heads/master' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a short branch name that exists' do
      let(:origin_ref) { 'master' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a full tag path' do
      let(:origin_ref) { 'refs/tags/v1.0.0' }

      it { is_expected.to be(false) }
    end

    context 'when ref is a tag name' do
      let(:origin_ref) { 'v1.0.0' }

      it { is_expected.to be(false) }
    end

    context 'when ref does not exist' do
      let(:origin_ref) { 'nonexistent' }

      it { is_expected.to be(false) }
    end

    context 'when ref is ambiguous' do
      let(:origin_ref) { 'ambiguous-branch-test' }

      before do
        repository.add_branch(project.creator, 'ambiguous-branch-test', 'master')
        repository.add_tag(project.creator, 'ambiguous-branch-test', 'master')
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#tag?' do
    subject { resolver.tag? }

    context 'when ref is a full tag path' do
      let(:origin_ref) { 'refs/tags/v1.0.0' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a short tag name that exists' do
      let(:origin_ref) { 'v1.0.0' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a full branch path' do
      let(:origin_ref) { 'refs/heads/master' }

      it { is_expected.to be(false) }
    end

    context 'when ref is a branch name' do
      let(:origin_ref) { 'master' }

      it { is_expected.to be(false) }
    end

    context 'when ref does not exist' do
      let(:origin_ref) { 'nonexistent' }

      it { is_expected.to be(false) }
    end

    context 'when ref is ambiguous' do
      let(:origin_ref) { 'ambiguous-tag-test' }

      before do
        repository.add_branch(project.creator, 'ambiguous-tag-test', 'master')
        repository.add_tag(project.creator, 'ambiguous-tag-test', 'master')
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#merge_request?' do
    subject { resolver.merge_request? }

    context 'when ref is a merge request ref' do
      let(:origin_ref) { 'refs/merge-requests/123/merge' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a merge request head ref' do
      let(:origin_ref) { 'refs/merge-requests/123/head' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a branch' do
      let(:origin_ref) { 'refs/heads/master' }

      it { is_expected.to be(false) }
    end

    context 'when ref is a tag' do
      let(:origin_ref) { 'refs/tags/v1.0.0' }

      it { is_expected.to be(false) }
    end
  end

  describe '#workload?' do
    subject { resolver.workload? }

    context 'when ref is a workload ref' do
      let(:origin_ref) { 'refs/workloads/abc123' }

      it { is_expected.to be(true) }
    end

    context 'when ref is a branch' do
      let(:origin_ref) { 'refs/heads/master' }

      it { is_expected.to be(false) }
    end

    context 'when ref is a tag' do
      let(:origin_ref) { 'refs/tags/v1.0.0' }

      it { is_expected.to be(false) }
    end
  end
end
