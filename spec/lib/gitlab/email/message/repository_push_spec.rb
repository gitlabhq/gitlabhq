require 'spec_helper'

describe Gitlab::Email::Message::RepositoryPush do
  include RepoHelpers

  let!(:group) { create(:group, name: 'my_group') }
  let!(:project) { create(:project, :repository, namespace: group) }
  let!(:author) { create(:author, name: 'Author') }

  let(:message) do
    described_class.new(Notify, project.id, opts)
  end

  context 'new commits have been pushed to repository' do
    let(:opts) do
      { author_id: author.id, ref: 'master', action: :push, compare: compare,
        send_from_committer_email: true }
    end
    let(:raw_compare) do
      Gitlab::Git::Compare.new(project.repository.raw_repository,
        sample_image_commit.id, sample_commit.id)
    end
    let(:compare) do
      Compare.decorate(raw_compare, project)
    end

    describe '#project' do
      subject { message.project }
      it { is_expected.to eq project }
      it { is_expected.to be_an_instance_of Project }
    end

    describe '#project_namespace' do
      subject { message.project_namespace }
      it { is_expected.to eq group }
      it { is_expected.to be_kind_of Namespace }
    end

    describe '#project_name_with_namespace' do
      subject { message.project_name_with_namespace }
      it { is_expected.to eq "#{group.name} / #{project.path}" }
    end

    describe '#author' do
      subject { message.author }
      it { is_expected.to eq author }
      it { is_expected.to be_an_instance_of User }
    end

    describe '#author_name' do
      subject { message.author_name }
      it { is_expected.to eq 'Author' }
    end

    describe '#commits' do
      subject { message.commits }
      it { is_expected.to be_kind_of Array }
      it { is_expected.to all(be_instance_of Commit) }
    end

    describe '#diffs' do
      subject { message.diffs }
      it { is_expected.to all(be_an_instance_of Gitlab::Diff::File) }
    end

    describe '#diffs_count' do
      subject { message.diffs_count }
      it { is_expected.to eq raw_compare.diffs.size }
    end

    describe '#compare' do
      subject { message.compare }
      it { is_expected.to be_an_instance_of Compare }
    end

    describe '#compare_timeout' do
      subject { message.compare_timeout }
      it { is_expected.to eq raw_compare.diffs.overflow? }
    end

    describe '#reverse_compare?' do
      subject { message.reverse_compare? }
      it { is_expected.to eq false }
    end

    describe '#disable_diffs?' do
      subject { message.disable_diffs? }
      it { is_expected.to eq false }
    end

    describe '#send_from_committer_email?' do
      subject { message.send_from_committer_email? }
      it { is_expected.to eq true }
    end

    describe '#action_name' do
      subject { message.action_name }
      it { is_expected.to eq 'pushed to' }
    end

    describe '#ref_name' do
      subject { message.ref_name }
      it { is_expected.to eq 'master' }
    end

    describe '#ref_type' do
      subject { message.ref_type }
      it { is_expected.to eq 'branch' }
    end

    describe '#target_url' do
      subject { message.target_url }
      it { is_expected.to include 'compare' }
      it { is_expected.to include compare.commits.first.parents.first.id }
      it { is_expected.to include compare.commits.last.id }
    end

    describe '#subject' do
      subject { message.subject }
      it { is_expected.to include "[Git][#{project.full_path}]" }
      it { is_expected.to include "#{compare.commits.length} commits" }
      it { is_expected.to include compare.commits.first.message.split("\n").first }
    end
  end
end
