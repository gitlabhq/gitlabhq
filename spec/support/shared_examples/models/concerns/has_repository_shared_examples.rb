# frozen_string_literal: true

RSpec.shared_examples 'model with repository' do
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

  describe '#ssh_url_to_repo' do
    it 'returns container ssh address' do
      expect(container.ssh_url_to_repo).to eq container.url_to_repo
    end
  end

  describe '#http_url_to_repo' do
    subject { container.http_url_to_repo }

    context 'when a custom HTTP clone URL root is not set' do
      it 'returns the url to the repo without a username' do
        expect(subject).to eq("#{container.web_url}.git")
        expect(subject).not_to include('@')
      end
    end

    context 'when a custom HTTP clone URL root is set' do
      before do
        stub_application_setting(custom_http_clone_url_root: custom_http_clone_url_root)
      end

      context 'when custom HTTP clone URL root has a relative URL root' do
        context 'when custom HTTP clone URL root ends with a slash' do
          let(:custom_http_clone_url_root) { 'https://git.example.com:51234/mygitlab/' }

          it 'returns the url to the repo, with the root replaced with the custom one' do
            expect(subject).to eq("#{custom_http_clone_url_root}#{expected_web_url_path}.git")
          end
        end

        context 'when custom HTTP clone URL root does not end with a slash' do
          let(:custom_http_clone_url_root) { 'https://git.example.com:51234/mygitlab' }

          it 'returns the url to the repo, with the root replaced with the custom one' do
            expect(subject).to eq("#{custom_http_clone_url_root}/#{expected_web_url_path}.git")
          end
        end
      end

      context 'when custom HTTP clone URL root does not have a relative URL root' do
        context 'when custom HTTP clone URL root ends with a slash' do
          let(:custom_http_clone_url_root) { 'https://git.example.com:51234/' }

          it 'returns the url to the repo, with the root replaced with the custom one' do
            expect(subject).to eq("#{custom_http_clone_url_root}#{expected_web_url_path}.git")
          end
        end

        context 'when custom HTTP clone URL root does not end with a slash' do
          let(:custom_http_clone_url_root) { 'https://git.example.com:51234' }

          it 'returns the url to the repo, with the root replaced with the custom one' do
            expect(subject).to eq("#{custom_http_clone_url_root}/#{expected_web_url_path}.git")
          end
        end
      end
    end
  end

  describe '#repository' do
    it 'returns valid repo' do
      expect(container.repository).to be_kind_of(expected_repository_klass)
    end
  end

  describe '#storage' do
    it 'returns valid storage' do
      expect(container.storage).to be_kind_of(expected_storage_klass)
    end
  end

  describe '#full_path' do
    it 'returns valid full_path' do
      expect(container.full_path).to eq(expected_full_path)
    end
  end

  describe '#empty_repo?' do
    context 'when the repo does not exist' do
      it 'returns true' do
        expect(stubbed_container.empty_repo?).to be(true)
      end
    end

    context 'when the repo exists' do
      it { expect(container.empty_repo?).to be(false) }

      it 'returns true when repository is empty' do
        allow(container.repository).to receive(:empty?).and_return(true)

        expect(container.empty_repo?).to be(true)
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
  end
end
