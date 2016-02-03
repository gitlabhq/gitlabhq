require 'spec_helper'

describe Repository, models: true do
  include RepoHelpers

  let(:repository) { create(:project).repository }
  let(:user) { create(:user) }

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

  describe :find_commits_by_message do
    subject { repository.find_commits_by_message('submodule').map{ |k| k.id } }

    it { is_expected.to include('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { is_expected.to include('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    it { is_expected.to include('cfe32cf61b73a0d5e9f13e774abde7ff789b1660') }
    it { is_expected.not_to include('913c66a37b4a45b9769037c55c2d238bd0942d2e') }
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

  describe "#license" do
    before do
      repository.send(:cache).expire(:license)
      TestBlob = Struct.new(:name)
    end

    it 'test selection preference' do
      files = [TestBlob.new('file'), TestBlob.new('license'), TestBlob.new('copying')]
      expect(repository.tree).to receive(:blobs).and_return(files)

      expect(repository.license.name).to eq('license')
    end

    it 'also accepts licence instead of license' do
      expect(repository.tree).to receive(:blobs).and_return([TestBlob.new('licence')])

      expect(repository.license.name).to eq('licence')
    end
  end

  describe :add_branch do
    context 'when pre hooks were successful' do
      it 'should run without errors' do
        hook = double(trigger: true)
        expect(Gitlab::Git::Hook).to receive(:new).exactly(3).times.and_return(hook)

        expect { repository.add_branch(user, 'new_feature', 'master') }.not_to raise_error
      end

      it 'should create the branch' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(true)

        branch = repository.add_branch(user, 'new_feature', 'master')

        expect(branch.name).to eq('new_feature')
      end
    end

    context 'when pre hooks failed' do
      it 'should get an error' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(false)

        expect do
          repository.add_branch(user, 'new_feature', 'master')
        end.to raise_error(GitHooksService::PreReceiveError)
      end

      it 'should not create the branch' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(false)

        expect do
          repository.add_branch(user, 'new_feature', 'master')
        end.to raise_error(GitHooksService::PreReceiveError)
        expect(repository.find_branch('new_feature')).to be_nil
      end
    end
  end

  describe :rm_branch do
    context 'when pre hooks were successful' do
      it 'should run without errors' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(true)

        expect { repository.rm_branch(user, 'feature') }.not_to raise_error
      end

      it 'should delete the branch' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(true)

        expect { repository.rm_branch(user, 'feature') }.not_to raise_error

        expect(repository.find_branch('feature')).to be_nil
      end
    end

    context 'when pre hooks failed' do
      it 'should get an error' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(false)

        expect do
          repository.rm_branch(user, 'new_feature')
        end.to raise_error(GitHooksService::PreReceiveError)
      end

      it 'should not delete the branch' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(false)

        expect do
          repository.rm_branch(user, 'feature')
        end.to raise_error(GitHooksService::PreReceiveError)
        expect(repository.find_branch('feature')).not_to be_nil
      end
    end
  end

  describe :commit_with_hooks do
    context 'when pre hooks were successful' do
      it 'should run without errors' do
        expect_any_instance_of(GitHooksService).to receive(:execute).and_return(true)

        expect do
          repository.commit_with_hooks(user, 'feature') { sample_commit.id }
        end.not_to raise_error
      end
    end

    context 'when pre hooks failed' do
      it 'should get an error' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return(false)

        expect do
          repository.commit_with_hooks(user, 'feature') { sample_commit.id }
        end.to raise_error(GitHooksService::PreReceiveError)
      end
    end
  end

  describe '#has_visible_content?' do
    subject { repository.has_visible_content? }

    describe 'when there are no branches' do
      before do
        allow(repository.raw_repository).to receive(:branch_count).and_return(0)
      end

      it { is_expected.to eq(false) }
    end

    describe 'when there are branches' do
      before do
        allow(repository.raw_repository).to receive(:branch_count).and_return(3)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe "Elastic search", elastic: true do
    before do
      Repository.__elasticsearch__.create_index!
    end

    after do
      Repository.__elasticsearch__.delete_index!
    end

    describe :find_commits_by_message_with_elastic do
      it "returns commits" do
        project = create :project

        project.repository.index_commits
        
        Repository.__elasticsearch__.refresh_index!

        expect(project.repository.find_commits_by_message_with_elastic('initial').first).to be_a(Commit)
        expect(project.repository.find_commits_by_message_with_elastic('initial').count).to eq(1)
      end
    end

    describe :parse_search_result_from_elastic do
      it "returns parsed result" do
        project = create :project

        project.repository.index_blobs

        Repository.__elasticsearch__.refresh_index!

        result = project.repository.search(
          'def popen',
          type: :blob,
          options: { highlight: true }
        )[:blobs][:results][0]

        parsed_result = project.repository.parse_search_result_from_elastic(result)

        expect(parsed_result.filename).to eq('files/ruby/popen.rb')
        expect(parsed_result.startline).to eq(2)
        expect(parsed_result.data).to include("Popen")
      end
    end
  end
end
