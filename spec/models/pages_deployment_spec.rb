# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDeployment do
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:ci_build).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }

    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_numericality_of(:size).only_integer.is_greater_than(0) }

    it { is_expected.to validate_presence_of(:file_count) }
    it { is_expected.to validate_numericality_of(:file_count).only_integer.is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_presence_of(:file_sha256) }

    it { is_expected.to validate_inclusion_of(:file_store).in_array(ObjectStorage::SUPPORTED_STORES) }

    it 'is valid when created from the factory' do
      expect(create(:pages_deployment)).to be_valid
    end
  end

  describe '.migrated_from_legacy_storage' do
    it 'only returns migrated deployments' do
      migrated_deployment = create_migrated_deployment(project)
      # create one other deployment
      create(:pages_deployment, project: project)

      expect(described_class.migrated_from_legacy_storage).to eq([migrated_deployment])
    end
  end

  context 'with deployments stored locally and remotely' do
    before do
      stub_pages_object_storage(::Pages::DeploymentUploader)
    end

    let!(:remote_deployment) { create(:pages_deployment, project: project, file_store: ::ObjectStorage::Store::REMOTE) }
    let!(:local_deployment) { create(:pages_deployment, project: project, file_store: ::ObjectStorage::Store::LOCAL) }

    describe '.with_files_stored_locally' do
      it 'only returns deployments with files stored locally' do
        expect(described_class.with_files_stored_locally).to contain_exactly(local_deployment)
      end
    end

    describe '.with_files_stored_remotely' do
      it 'only returns deployments with files stored remotely' do
        expect(described_class.with_files_stored_remotely).to contain_exactly(remote_deployment)
      end
    end
  end

  describe '#migrated?' do
    it 'returns false for normal deployment' do
      deployment = create(:pages_deployment)

      expect(deployment.migrated?).to eq(false)
    end

    it 'returns true for migrated deployment' do
      deployment = create_migrated_deployment(project)

      expect(deployment.migrated?).to eq(true)
    end
  end

  def create_migrated_deployment(project)
    public_path = File.join(project.pages_path, "public")
    FileUtils.mkdir_p(public_path)
    File.open(File.join(project.pages_path, "public/index.html"), "w") do |f|
      f.write("Hello!")
    end

    expect(::Pages::MigrateLegacyStorageToDeploymentService.new(project).execute[:status]).to eq(:success)

    project.reload.pages_metadatum.pages_deployment
  ensure
    FileUtils.rm_rf(public_path)
  end

  describe 'default for file_store' do
    let(:deployment) do
      filepath = Rails.root.join("spec/fixtures/pages.zip")

      described_class.create!(
        project: project,
        file: fixture_file_upload(filepath),
        file_sha256: Digest::SHA256.file(filepath).hexdigest,
        file_count: 3
      )
    end

    it 'uses local store when object storage is not enabled' do
      expect(deployment.file_store).to eq(ObjectStorage::Store::LOCAL)
    end

    it 'uses remote store when object storage is enabled' do
      stub_pages_object_storage(::Pages::DeploymentUploader)

      expect(deployment.file_store).to eq(ObjectStorage::Store::REMOTE)
    end
  end

  it 'saves size along with the file' do
    deployment = create(:pages_deployment)
    expect(deployment.size).to eq(deployment.file.size)
  end

  describe '.older_than' do
    it 'returns deployments with lower id' do
      old_deployments = create_list(:pages_deployment, 2)

      deployment = create(:pages_deployment)

      # new deployment
      create(:pages_deployment)

      expect(PagesDeployment.older_than(deployment.id)).to eq(old_deployments)
    end
  end
end
