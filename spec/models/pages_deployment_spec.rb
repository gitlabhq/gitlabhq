# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDeployment, feature_category: :pages do
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

  context 'when uploading the file' do
    before do
      stub_pages_object_storage(::Pages::DeploymentUploader)
    end

    it 'stores the file outsize of the transaction' do
      expect_next_instance_of(PagesDeployment) do |deployment|
        expect(deployment).to receive(:store_file_now!)
      end

      create(:pages_deployment, project: project)
    end

    it 'does nothing when the file did not change' do
      deployment = create(:pages_deployment, project: project)

      expect(deployment).not_to receive(:store_file_now!)

      deployment.touch
    end
  end

  describe '.deactivate_deployments_older_than', :freeze_time do
    let!(:other_project_deployment) do
      create(:pages_deployment)
    end

    let!(:other_path_prefix_deployment) do
      create(:pages_deployment, project: project, path_prefix: 'other')
    end

    let!(:deactivated_deployment) do
      create(:pages_deployment, project: project, deleted_at: 5.minutes.ago)
    end

    it 'updates only older deployments for the same project and path prefix' do
      deployment1 = create(:pages_deployment, project: project, updated_at: 5.minutes.ago)
      deployment2 = create(:pages_deployment, project: project, updated_at: 5.minutes.ago)
      deployment3 = create(:pages_deployment, project: project, updated_at: 5.minutes.ago)

      expect { described_class.deactivate_deployments_older_than(deployment2) }
        .to change { deployment1.reload.deleted_at }
        .from(nil).to(Time.zone.now)
        .and change { deployment1.reload.updated_at }
        .to(Time.zone.now)

      expect(deployment2.reload.deleted_at).to be_nil
      expect(deployment3.reload.deleted_at).to be_nil
      expect(other_project_deployment.deleted_at).to be_nil
      expect(other_path_prefix_deployment.reload.deleted_at).to be_nil
      expect(deactivated_deployment.reload.deleted_at).to eq(5.minutes.ago)
    end

    it 'updates only older deployments for the same project with the given time' do
      deployment1 = create(:pages_deployment, project: project, updated_at: 5.minutes.ago)
      deployment2 = create(:pages_deployment, project: project, updated_at: 5.minutes.ago)
      deployment3 = create(:pages_deployment, project: project, updated_at: 5.minutes.ago)
      time = 30.minutes.from_now

      expect { described_class.deactivate_deployments_older_than(deployment2, time: time) }
        .to change { deployment1.reload.deleted_at }
        .from(nil).to(time)
        .and change { deployment1.reload.updated_at }
        .to(Time.zone.now)

      expect(deployment2.reload.deleted_at).to be_nil
      expect(deployment3.reload.deleted_at).to be_nil
      expect(other_project_deployment.deleted_at).to be_nil
      expect(other_path_prefix_deployment.reload.deleted_at).to be_nil
      expect(deactivated_deployment.reload.deleted_at).to eq(5.minutes.ago)
    end
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

      expect(described_class.older_than(deployment.id)).to eq(old_deployments)
    end
  end
end
