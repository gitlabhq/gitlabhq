require 'spec_helper'

describe Repository do
  include RepoHelpers

  let(:repository) { create(:project).repository }

  describe :branch_names_contains do
    subject { repository.branch_names_contains(sample_commit.id) }

    it { is_expected.to include('master') }
    it { is_expected.not_to include('feature') }
    it { is_expected.not_to include('fix') }
  end

  describe :tag_names_contains do
    subject { repository.tag_names_contains(sample_commit.id) }

    it { is_expected.to include('v1.1.0') }
    it { is_expected.not_to include('v1.0.0') }
  end

  describe :last_commit_for_path do
    subject { repository.last_commit_for_path(sample_commit.id, '.gitignore').id }

    it { is_expected.to eq('c1acaa58bbcbc3eafe538cb8274ba387047b69f8') }
  end

  describe :blob_at do
    context 'blank sha' do
      subject { repository.blob_at(Gitlab::Git::BLANK_SHA, '.gitignore') }

      it { is_expected.to be_nil }
    end
  end

  describe :merged_to_root_ref? do
    context 'merged branch' do
      subject { repository.merged_to_root_ref?('improve/awesome') }

      it { is_expected.to be_truthy }
    end
  end

  describe :can_be_merged? do
    context 'mergeable branches' do
      subject { repository.can_be_merged?('0b4bc9a49b562e85de7cc9e834518ea6828729b9', 'master') }

      it { is_expected.to be_truthy }
    end

    context 'non-mergeable branches' do
      subject { repository.can_be_merged?('bb5206fee213d983da88c47f9cf4cc6caf9c66dc', 'feature') }

      it { is_expected.to be_falsey }
    end

    context 'non merged branch' do
      subject { repository.merged_to_root_ref?('fix') }

      it { is_expected.to be_falsey }
    end

    context 'non existent branch' do
      subject { repository.merged_to_root_ref?('non_existent_branch') }

      it { is_expected.to be_nil }
    end
  end

  describe "search_files" do
    let(:results) { repository.search_files('feature', 'master') }
    subject { results }

    it { is_expected.to be_an Array }

    describe 'result' do
      subject { results.first }

      it { is_expected.to be_an String }
      it { expect(subject.lines[2]).to eq("master:CHANGELOG:188:  - Feature: Replace teams with group membership\n") }
    end

    describe 'parsing result' do
      subject { repository.parse_search_result(results.first) }

      it { is_expected.to be_an OpenStruct }
      it { expect(subject.filename).to eq('CHANGELOG') }
      it { expect(subject.ref).to eq('master') }
      it { expect(subject.startline).to eq(186) }
      it { expect(subject.data.lines[2]).to eq("  - Feature: Replace teams with group membership\n") }
    end
  end
end
