# frozen_string_literal: true

RSpec.shared_examples 'model with repository' do
  let(:container) { raise NotImplementedError }
  let(:stubbed_container) { raise NotImplementedError }
  let(:expected_full_path) { raise NotImplementedError }
  let(:expected_web_url_path) { expected_full_path }
  let(:expected_repo_url_path) { expected_full_path }
  let(:expected_lfs_enabled) { false }

  it 'container class includes HasRepository' do
    # NOTE: This is not enforced at runtime, since we also need to support Geo::DeletedProject
    expect(described_class).to include_module(HasRepository)
    expect(container).to be_kind_of(HasRepository)
    expect(stubbed_container).to be_kind_of(HasRepository)
  end

  describe '#commits_by' do
    let(:commits) { container.repository.commits('HEAD', limit: 3).commits }
    let(:commit_shas) { commits.map(&:id) }

    it 'retrieves several commits from the repository by oid' do
      expect(container.commits_by(oids: commit_shas)).to eq commits
    end
  end

  describe "#web_url" do
    context 'when given the only_path option' do
      subject { container.web_url(only_path: only_path) }

      context 'when only_path is false' do
        let(:only_path) { false }

        it 'returns the full web URL for this repo' do
          expect(subject).to eq("#{Gitlab.config.gitlab.url}/#{expected_web_url_path}")
        end
      end

      context 'when only_path is true' do
        let(:only_path) { true }

        it 'returns the relative web URL for this repo' do
          expect(subject).to eq("/#{expected_web_url_path}")
        end
      end

      context 'when only_path is nil' do
        let(:only_path) { nil }

        it 'returns the full web URL for this repo' do
          expect(subject).to eq("#{Gitlab.config.gitlab.url}/#{expected_web_url_path}")
        end
      end
    end

    context 'when not given the only_path option' do
      it 'returns the full web URL for this repo' do
        expect(container.web_url).to eq("#{Gitlab.config.gitlab.url}/#{expected_web_url_path}")
      end
    end
  end

  describe '#url_to_repo' do
    it 'returns the SSH URL to the repository' do
      expect(container.url_to_repo).to eq(container.ssh_url_to_repo)
    end
  end

  describe '#ssh_url_to_repo' do
    it 'returns the SSH URL to the repository' do
      expect(container.ssh_url_to_repo).to eq("#{Gitlab.config.gitlab_shell.ssh_path_prefix}#{expected_repo_url_path}.git")
    end
  end

  describe '#http_url_to_repo' do
    it 'returns the HTTP URL to the repository' do
      expect(container.http_url_to_repo).to eq("#{Gitlab.config.gitlab.url}/#{expected_repo_url_path}.git")
    end
  end

  describe '#repository' do
    it 'returns valid repo' do
      expect(container.repository).to be_kind_of(Repository)
    end

    it 'uses the same container' do
      expect(container.repository.container).to be(container)
    end
  end

  describe '#storage' do
    it 'returns valid storage' do
      expect(container.storage).to be_kind_of(Storage::Hashed)
    end
  end

  describe '#full_path' do
    it 'returns valid full_path' do
      expect(container.full_path).to eq(expected_full_path)
    end
  end

  describe '#lfs_enabled?' do
    before do
      stub_lfs_setting(enabled: true)
    end

    it 'returns the expected value' do
      expect(container.lfs_enabled?).to eq(expected_lfs_enabled)
    end
  end

  describe '#empty_repo?' do
    context 'when the repo does not exist' do
      it 'returns true' do
        expect(stubbed_container.empty_repo?).to be(true)
      end
    end

    context 'when the repo exists' do
      it 'returns the empty state of the repository' do
        expect(container.empty_repo?).to be(container.repository.empty?)
      end
    end
  end

  describe '#valid_repo?' do
    it { expect(stubbed_container.valid_repo?).to be(false)}
    it { expect(container.valid_repo?).to be(true) }
  end

  describe '#repository_exists?' do
    it { expect(stubbed_container.repository_exists?).to be(false)}
    it { expect(container.repository_exists?).to be(true) }
  end

  describe '#repo_exists?' do
    it { expect(stubbed_container.repo_exists?).to be(false)}
    it { expect(container.repo_exists?).to be(true) }
  end

  describe '#root_ref' do
    let(:root_ref) { container.repository.root_ref }

    it { expect(container.root_ref?(root_ref)).to be(true) }
    it { expect(container.root_ref?('HEAD')).to be(false) }
    it { expect(container.root_ref?('foo')).to be(false) }
  end

  describe 'Respond to' do
    it { is_expected.to respond_to(:base_dir) }
    it { is_expected.to respond_to(:disk_path) }
    it { is_expected.to respond_to(:gitlab_shell) }
  end

  describe '#change_head' do
    it 'delegates #change_head to repository' do
      expect(stubbed_container.repository).to receive(:change_head).with('foo')

      stubbed_container.change_head('foo')
    end
  end

  describe '#after_repository_change_head' do
    it 'calls #reload_default_branch' do
      expect(stubbed_container).to receive(:reload_default_branch)

      stubbed_container.after_repository_change_head
    end
  end
end
