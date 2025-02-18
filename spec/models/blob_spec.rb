# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blob, feature_category: :source_code_management do
  include FakeBlobHelpers

  using RSpec::Parameterized::TableSyntax

  let(:project) { build(:project) }
  let(:personal_snippet) { build(:personal_snippet) }
  let(:project_snippet) { build(:project_snippet, project: project) }

  let(:repository) { project.repository }
  let(:lfs_enabled) { true }

  before do
    allow(repository).to receive(:lfs_enabled?) { lfs_enabled }
  end

  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil)).to be_nil
    end
  end

  describe '.lazy' do
    let(:commit_id) { 'e63f41fe459e62e1228fcef60d7189127aeba95a' }
    let(:blob_size_limit) { 10 * 1024 * 1024 }

    shared_examples '.lazy checks' do
      it 'does not fetch blobs when none are accessed' do
        expect(container.repository).not_to receive(:blobs_at)

        described_class.lazy(container.repository, commit_id, 'CHANGELOG')
      end

      it 'fetches all blobs for the same repository when one is accessed' do
        expect(container.repository).to receive(:blobs_at)
          .with([[commit_id, 'CHANGELOG'], [commit_id, 'CONTRIBUTING.md']], blob_size_limit: blob_size_limit)
          .once.and_call_original
        expect(other_container.repository).not_to receive(:blobs_at)

        changelog = described_class.lazy(container.repository, commit_id, 'CHANGELOG')
        contributing = described_class.lazy(same_container.repository, commit_id, 'CONTRIBUTING.md')

        described_class.lazy(other_container.repository, commit_id, 'CHANGELOG')

        # Access property so the values are loaded
        changelog.id
        contributing.id
      end

      it 'does not include blobs from previous requests in later requests' do
        changelog = described_class.lazy(container.repository, commit_id, 'CHANGELOG')
        contributing = described_class.lazy(same_container.repository, commit_id, 'CONTRIBUTING.md')

        # Access property so the values are loaded
        changelog.id
        contributing.id

        readme = described_class.lazy(container.repository, commit_id, 'README.md')

        expect(container.repository).to receive(:blobs_at)
          .with([[commit_id, 'README.md']], blob_size_limit: blob_size_limit).once.and_call_original

        readme.id
      end
    end

    context 'with project' do
      let_it_be(:container) { create(:project, :repository) }
      let_it_be(:same_container) { Project.find(container.id) }
      let_it_be(:other_container) { create(:project, :repository) }

      it_behaves_like '.lazy checks'

      context 'when the blob size limit is different' do
        it 'fetches all blobs for the same repository and same blob size limit when one is accessed' do
          expect(container.repository).to receive(:blobs_at)
            .with([[commit_id, 'CHANGELOG']], blob_size_limit: 10)
            .once.and_call_original

          expect(same_container.repository).to receive(:blobs_at)
            .with([[commit_id, 'CONTRIBUTING.md'], [commit_id, 'README.md']], blob_size_limit: 20)
            .once.and_call_original

          expect(other_container.repository).not_to receive(:blobs_at)

          changelog = described_class.lazy(container.repository, commit_id, 'CHANGELOG', blob_size_limit: 10)
          contributing = described_class.lazy(same_container.repository, commit_id, 'CONTRIBUTING.md',
            blob_size_limit: 20)
          described_class.lazy(same_container.repository, commit_id, 'README.md',
            blob_size_limit: 20)

          described_class.lazy(other_container.repository, commit_id, 'CHANGELOG', blob_size_limit: 30)

          # Access property so the values are loaded
          changelog.id
          contributing.id
        end
      end

      context 'with personal snippet' do
        let_it_be(:container) { create(:personal_snippet, :repository) }
        let_it_be(:same_container) { PersonalSnippet.find(container.id) }
        let_it_be(:other_container) { create(:personal_snippet, :repository) }

        it_behaves_like '.lazy checks'
      end

      context 'with project snippet' do
        let_it_be(:container) { create(:project_snippet, :repository) }
        let_it_be(:same_container) { ProjectSnippet.find(container.id) }
        let_it_be(:other_container) { create(:project_snippet, :repository) }

        it_behaves_like '.lazy checks'
      end
    end
  end

  describe '#data' do
    shared_examples '#data checks' do
      context 'using a binary blob' do
        it 'returns the data as-is' do
          data = "\n\xFF\xB9\xC3"
          blob = fake_blob(binary: true, data: data, container: container)

          expect(blob.data).to eq(data)
        end
      end

      context 'using a text blob' do
        it 'converts the data to UTF-8' do
          blob = fake_blob(binary: false, data: "\n\xFF\xB9\xC3", container: container)

          expect(blob.data).to eq("\n���")
        end
      end
    end

    context 'with project' do
      let(:container) { project }

      it_behaves_like '#data checks'
    end

    context 'with personal snippet' do
      let(:container) { personal_snippet }

      it_behaves_like '#data checks'
    end

    context 'with project snippet' do
      let(:container) { project_snippet }

      it_behaves_like '#data checks'
    end
  end

  describe '#external_storage_error?' do
    subject { blob.external_storage_error? }

    context 'if the blob is stored in LFS' do
      let(:blob) { fake_blob(path: 'file.pdf', lfs: true) }

      context 'when LFS is enabled' do
        let(:lfs_enabled) { true }

        it { is_expected.to be_falsy }
      end

      context 'when LFS is not enabled' do
        let(:lfs_enabled) { false }

        it { is_expected.to be_truthy }
      end
    end

    context 'if the blob is not stored in LFS' do
      let(:blob) { fake_blob(path: 'file.md') }

      it { is_expected.to be_falsy }
    end
  end

  describe '#stored_externally?' do
    subject { blob.stored_externally? }

    context 'if the blob is stored in LFS' do
      let(:blob) { fake_blob(path: 'file.pdf', lfs: true) }

      context 'when LFS is enabled' do
        let(:lfs_enabled) { true }

        it { is_expected.to be_truthy }
      end

      context 'when LFS is not enabled' do
        let(:lfs_enabled) { false }

        it { is_expected.to be_falsy }
      end
    end

    context 'if the blob is not stored in LFS' do
      let(:blob) { fake_blob(path: 'file.md') }

      it { is_expected.to be_falsy }
    end
  end

  describe '#binary?' do
    context 'an lfs object' do
      where(:filename, :is_binary) do
        'file.pdf' | true
        'file.md'  | false
        'file.txt' | false
        'file.ics' | false
        'file.rb'  | false
        'file.exe' | true
        'file.ini' | false
        'file.wtf' | true
      end

      with_them do
        let(:blob) { fake_blob(path: filename, lfs: true, container: project) }

        it { expect(blob.binary?).to eq(is_binary) }
      end
    end

    context 'a non-lfs object' do
      let(:blob) { fake_blob(path: 'anything', container: project) }

      it 'delegates to binary_in_repo?' do
        expect(blob).to receive(:binary_in_repo?) { :result }

        expect(blob.binary?).to eq(:result)
      end
    end
  end

  describe '#symlink?' do
    it 'is true for symlinks' do
      symlink_blob = fake_blob(path: 'file', mode: '120000')

      expect(symlink_blob.symlink?).to eq true
    end

    it 'is false for non-symlinks' do
      non_symlink_blob = fake_blob(path: 'file', mode: '100755')

      expect(non_symlink_blob.symlink?).to eq false
    end
  end

  describe '#executable?' do
    it 'is true for executables' do
      executable_blob = fake_blob(path: 'file', mode: '100755')

      expect(executable_blob.executable?).to eq true
    end

    it 'is false for non-executables' do
      non_executable_blob = fake_blob(path: 'file', mode: '100655')

      expect(non_executable_blob.executable?).to eq false
    end
  end

  describe '#extension' do
    it 'returns the extension' do
      blob = fake_blob(path: 'file.md')

      expect(blob.extension).to eq('md')
    end
  end

  describe '#file_type' do
    it 'returns the file type' do
      blob = fake_blob(path: 'README.md')

      expect(blob.file_type).to eq(:readme)
    end
  end

  describe '#file_hash' do
    it 'returns the file hash' do
      blob = fake_blob(path: 'README.md')

      expect(blob.file_hash).to include('b3356305')
    end
  end

  describe '#simple_viewer' do
    context 'when the blob is empty' do
      it 'returns an empty viewer' do
        blob = fake_blob(data: '', size: 0)

        expect(blob.simple_viewer).to be_a(BlobViewer::Empty)
      end
    end

    context 'when the file represented by the blob is binary' do
      it 'returns a download viewer' do
        blob = fake_blob(binary: true)

        expect(blob.simple_viewer).to be_a(BlobViewer::Download)
      end
    end

    context 'when the file represented by the blob is text-based' do
      it 'returns a text viewer' do
        blob = fake_blob

        expect(blob.simple_viewer).to be_a(BlobViewer::Text)
      end
    end
  end

  describe '#rich_viewer' do
    context 'when the blob has an external storage error' do
      let(:lfs_enabled) { false }

      it 'returns nil' do
        blob = fake_blob(path: 'file.pdf', lfs: true)

        expect(blob.rich_viewer).to be_nil
      end
    end

    context 'when the blob is empty' do
      it 'returns nil' do
        blob = fake_blob(data: '')

        expect(blob.rich_viewer).to be_nil
      end
    end

    context 'when the blob is stored externally' do
      it 'returns a matching viewer' do
        blob = fake_blob(path: 'file.pdf', lfs: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::PDF)
      end
    end

    context 'when the blob is binary' do
      it 'returns a matching binary viewer' do
        blob = fake_blob(path: 'file.pdf', binary: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::PDF)
      end
    end

    context 'when the blob is text-based' do
      it 'returns a matching text-based viewer' do
        blob = fake_blob(path: 'file.md')

        expect(blob.rich_viewer).to be_a(BlobViewer::Markup)
      end
    end

    context 'when the blob is video' do
      it 'returns a video viewer' do
        blob = fake_blob(path: 'file.mp4', binary: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::Video)
      end
    end

    context 'when the blob is audio' do
      it 'returns an audio viewer' do
        blob = fake_blob(path: 'file.wav', binary: true)

        expect(blob.rich_viewer).to be_a(BlobViewer::Audio)
      end
    end

    context 'when the blob is a graph' do
      context 'and PlantUML is enabled' do
        it 'returns a matching viewer for PlantUML' do
          blob = fake_blob(path: 'file.puml')
          stub_application_setting(plantuml_enabled: true)

          expect(blob.rich_viewer).to be_a(BlobViewer::Graph)
        end
      end

      context 'and Kroki is enabled' do
        it 'returns a matching viewer for PlantUML' do
          blob = fake_blob(path: 'file.puml')
          stub_application_setting(kroki_enabled: true)

          expect(blob.rich_viewer).to be_a(BlobViewer::Graph)
        end

        it 'returns a matching viewer for GraphViz' do
          blob = fake_blob(path: 'file.dot')
          stub_application_setting(kroki_enabled: true)

          expect(blob.rich_viewer).to be_a(BlobViewer::Graph)
        end

        it 'returns a matching viewer for Nomnoml' do
          blob = fake_blob(path: 'file.noml')
          stub_application_setting(kroki_enabled: true)

          expect(blob.rich_viewer).to be_a(BlobViewer::Graph)
        end
      end

      context 'default' do
        it 'returns viewer for Mermaid' do
          blob = fake_blob(path: 'file.mermaid')

          expect(blob.rich_viewer).to be_a(BlobViewer::Graph)
        end

        it 'returns nil for PlantUML' do
          blob = fake_blob(path: 'file.puml')

          expect(blob.rich_viewer).to be_nil
        end

        it 'returns nil for GraphViz' do
          blob = fake_blob(path: 'file.dot')

          expect(blob.rich_viewer).to be_nil
        end

        it 'returns nil for GraphViz' do
          blob = fake_blob(path: 'file.noml')

          expect(blob.rich_viewer).to be_nil
        end
      end
    end
  end

  describe '#auxiliary_viewer' do
    context 'when the blob has an external storage error' do
      let(:lfs_enabled) { false }

      it 'returns nil' do
        blob = fake_blob(path: 'LICENSE', lfs: true)

        expect(blob.auxiliary_viewer).to be_nil
      end
    end

    context 'when the blob is empty' do
      it 'returns nil' do
        blob = fake_blob(data: '')

        expect(blob.auxiliary_viewer).to be_nil
      end
    end

    context 'when the blob is stored externally' do
      it 'returns a matching viewer' do
        blob = fake_blob(path: 'LICENSE', lfs: true)

        expect(blob.auxiliary_viewer).to be_a(BlobViewer::License)
      end
    end

    context 'when the blob is binary' do
      it 'returns nil' do
        blob = fake_blob(path: 'LICENSE', binary: true)

        expect(blob.auxiliary_viewer).to be_nil
      end
    end

    context 'when the blob is text-based' do
      it 'returns a matching text-based viewer' do
        blob = fake_blob(path: 'LICENSE')

        expect(blob.auxiliary_viewer).to be_a(BlobViewer::License)
      end
    end

    context 'when the blob is GitlabCiYml' do
      it 'returns a matching viewer for .gitlab-ci.yml' do
        blob = fake_blob(path: '.gitlab-ci.yml')

        expect(blob.auxiliary_viewer).to be_a(BlobViewer::GitlabCiYml)
      end

      it 'returns nil for non .gitlab-ci.yml' do
        blob = fake_blob(path: 'custom-ci.yml')

        expect(blob.auxiliary_viewer).to be_nil
      end

      context 'when the project has a custom CI config path' do
        let(:project) { build(:project, ci_config_path: 'custom-ci.yml') }

        it 'returns a matching viewer for the custom CI file' do
          blob = fake_blob(path: 'custom-ci.yml')

          expect(blob.auxiliary_viewer).to be_a(BlobViewer::GitlabCiYml)
        end

        it 'returns nil for the incorrect CI file' do
          blob = fake_blob(path: '.gitlab-ci.yml')

          expect(blob.auxiliary_viewer).to be_nil
        end
      end
    end
  end

  describe '#rendered_as_text?' do
    subject { blob.rendered_as_text?(ignore_errors: ignore_errors) }

    context 'when ignoring errors' do
      let(:ignore_errors) { true }

      context 'when the simple viewer is text-based' do
        let(:blob) { fake_blob(path: 'file.md', size: 100.megabytes) }

        it { is_expected.to be_truthy }
      end

      context 'when the simple viewer is binary' do
        let(:blob) { fake_blob(path: 'file.pdf', binary: true, size: 100.megabytes) }

        it { is_expected.to be_falsy }
      end
    end

    context 'when not ignoring errors' do
      let(:ignore_errors) { false }

      context 'when the viewer has render errors' do
        let(:blob) { fake_blob(path: 'file.md', size: 100.megabytes) }

        it { is_expected.to be_falsy }
      end

      context "when the viewer doesn't have render errors" do
        let(:blob) { fake_blob(path: 'file.md') }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe 'policy' do
    let(:project) { build(:project) }

    subject { described_class.new(fake_blob(path: 'foo'), project) }

    it 'works with policy' do
      expect(Ability.allowed?(project.creator, :read_blob, subject)).to be_truthy
    end

    context 'when project is nil' do
      subject { described_class.new(fake_blob(path: 'foo')) }

      it 'does not err' do
        expect(Ability.allowed?(project.creator, :read_blob, subject)).to be_falsey
      end
    end
  end
end
