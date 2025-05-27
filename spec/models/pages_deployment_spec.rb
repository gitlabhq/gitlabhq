# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDeployment, feature_category: :pages do
  using RSpec::Parameterized::TableSyntax
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

    it_behaves_like 'object storable' do
      let(:locally_stored) { create(:pages_deployment, project: project, file_store: ::ObjectStorage::Store::LOCAL) }
      let(:remotely_stored) { create(:pages_deployment, project: project, file_store: ::ObjectStorage::Store::REMOTE) }
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

  describe '#upload_ready' do
    it 'marks #upload_ready as true when upload finishes' do
      deployment = build(:pages_deployment)

      expect { deployment.save! }
        .to change { deployment.upload_ready }
        .from(false).to(true)
    end
  end

  describe '.deactivate_all', :freeze_time do
    let!(:deployment) { create(:pages_deployment, project: project, updated_at: 5.minutes.ago) }
    let!(:nil_path_prefix_deployment) { create(:pages_deployment, project: project, path_prefix: nil) }
    let!(:empty_path_prefix_deployment) { create(:pages_deployment, project: project, path_prefix: '') }

    let!(:other_project_deployment) { create(:pages_deployment) }
    let!(:deactivated_deployment) { create(:pages_deployment, project: project, deleted_at: 5.minutes.ago) }

    it 'updates only older deployments for the same project and path prefix' do
      expect { described_class.deactivate_all(project) }
        .to change { deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
        .and change { deployment.reload.updated_at }.to(Time.zone.now)
        .and change { nil_path_prefix_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
        .and change { empty_path_prefix_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
        .and not_change { other_project_deployment.reload.deleted_at }
        .and not_change { deactivated_deployment.reload.deleted_at }
    end
  end

  describe '.deactivate_deployments_older_than', :freeze_time do
    let!(:nil_path_prefix_deployment) { create(:pages_deployment, project: project, path_prefix: nil) }
    let!(:empty_path_prefix_deployment) { create(:pages_deployment, project: project, path_prefix: '') }
    let!(:older_deployment) { create(:pages_deployment, project: project, updated_at: 5.minutes.ago) }
    let!(:reference_deployment) { create(:pages_deployment, project: project, updated_at: 5.minutes.ago) }
    let!(:newer_deployment) { create(:pages_deployment, project: project, updated_at: 5.minutes.ago) }

    let!(:other_project_deployment) { create(:pages_deployment) }
    let!(:other_path_prefix_deployment) { create(:pages_deployment, project: project, path_prefix: 'other') }
    let!(:deactivated_deployment) { create(:pages_deployment, project: project, deleted_at: 5.minutes.ago) }

    it 'updates only older deployments for the same project and path prefix' do
      expect { described_class.deactivate_deployments_older_than(reference_deployment) }
        .to change { older_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
        .and change { older_deployment.reload.updated_at }.to(Time.zone.now)
        .and change { nil_path_prefix_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
        .and change { empty_path_prefix_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
        .and not_change { reference_deployment.reload.deleted_at }
        .and not_change { newer_deployment.reload.deleted_at }
        .and not_change { other_project_deployment.reload.deleted_at }
        .and not_change { other_path_prefix_deployment.reload.deleted_at }
        .and not_change { deactivated_deployment.reload.deleted_at }
    end

    it 'updates only older deployments for the same project with the given time' do
      time = 30.minutes.from_now

      expect { described_class.deactivate_deployments_older_than(reference_deployment, time: time) }
        .to change { older_deployment.reload.deleted_at }.from(nil).to(time)
        .and change { older_deployment.reload.updated_at }.to(Time.zone.now)
        .and change { nil_path_prefix_deployment.reload.deleted_at }.from(nil).to(time)
        .and change { empty_path_prefix_deployment.reload.deleted_at }.from(nil).to(time)
        .and not_change { reference_deployment.reload.deleted_at }
        .and not_change { newer_deployment.reload.deleted_at }
        .and not_change { other_project_deployment.reload.deleted_at }
        .and not_change { other_path_prefix_deployment.reload.deleted_at }
        .and not_change { deactivated_deployment.reload.deleted_at }
    end
  end

  describe '.count_versioned_deployments_for' do
    it 'counts the number of active pages deployments for a list of projects' do
      group = create(:group)
      project1 = create(:project, group: group).tap do |project|
        # not versioned
        create(:pages_deployment, project: project)
        # versioned, active
        create(:pages_deployment, project: project, path_prefix: 'v1')
        # versioned, not active
        create(:pages_deployment, project: project, path_prefix: 'v2', deleted_at: 1.day.from_now)
      end
      project2 = create(:project, group: group).tap do |project|
        # not versioned
        create(:pages_deployment, project: project)
        # versioned, active
        create(:pages_deployment, project: project, path_prefix: 'v1')
        # versioned, not active
        create(:pages_deployment, project: project, path_prefix: 'v2', deleted_at: 1.day.from_now)
      end

      expect(described_class.count_versioned_deployments_for([project1, project2], 10)).to eq(2)
      expect(described_class.count_versioned_deployments_for([project1, project2], 1)).to eq(1)
    end

    it 'counts the number of active pages deployments for a single project' do
      group = create(:group)
      project = create(:project, group: group).tap do |project|
        create(:pages_deployment, project: project, path_prefix: 'v1')
        create(:pages_deployment, project: project, path_prefix: 'v2')
        create(:pages_deployment, project: project, path_prefix: 'v3')
      end

      expect(described_class.count_versioned_deployments_for(project, 10)).to eq(3)
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

  # Verify that calling deactivate on an instance sets the deleted_at value to now
  describe '.deactivate (instance method)' do
    it 'sets deleted_at to the current time', :freeze_time do
      deployment = create(:pages_deployment)
      expect { deployment.deactivate }
        .to change { deployment.deleted_at }.from(nil).to(Time.zone.now)
    end
  end

  describe '.restore' do
    it 'sets deleted_at to nil', :freeze_time do
      deployment = create(:pages_deployment, deleted_at: Time.zone.now)
      expect { deployment.restore }
        .to change { deployment.deleted_at }.from(Time.zone.now).to(nil)
    end

    context 'when restoring a deleted page deployment with path_prefix not nil', :freeze_time do
      let(:deleted_deployment) do
        create(:pages_deployment, project: project, deleted_at: Time.zone.now, path_prefix: 'test')
      end

      let(:past_deactivation_date) { '2020-02-16' }

      where(:path_prefix, :deleted_at) do
        'test2' | nil # active deployment with different path_prefix stays active
        'test'  | ref(:past_deactivation_date)   # stopped deployment with same path_prefix stays stopped
        'test2' | ref(:past_deactivation_date)   # stopped deployment with different path_prefix stays stopped
        '' | nil # active deployment with no path_prefix stays active
        '' | ref(:past_deactivation_date) # stopped deployment with no path_prefix stays stopped
      end

      with_them do
        it 'deactivate active deployment with diff paths and others stays the same' do
          deployment = create(:pages_deployment, project: project, path_prefix: path_prefix, deleted_at: deleted_at)
          expect { deleted_deployment.restore }
          .not_to change { deployment.reload.deleted_at }
        end
      end

      it 'deactivate active deployment with same path_prefix' do
        active_deployment = create(:pages_deployment, project: project, path_prefix: 'test')
        expect { deleted_deployment.restore }
          .to change { active_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
      end
    end

    context 'when restoring a deleted page deployment with path_prefix nil', :freeze_time do
      let(:deleted_deployment) do
        create(:pages_deployment, project: project, deleted_at: Time.zone.now, path_prefix: '')
      end

      let(:past_deactivation_date) { '2020-02-16' }

      where(:path_prefix, :deleted_at) do
        'test2' | nil # active deployment with a path_prefix stays active
        'test2' | ref(:past_deactivation_date)   # stopped deployment with a path_prefix stays stopped
        ''      | ref(:past_deactivation_date)   # stopped deployment with no path_prefix stays stopped
      end

      with_them do
        it 'deactivate active deployment with diff paths and others stays the same' do
          deployment = create(:pages_deployment, project: project, path_prefix: path_prefix, deleted_at: deleted_at)
          expect { deleted_deployment.restore }
          .not_to change { deployment.reload.deleted_at }
        end
      end

      it 'deactivate active deployment with same path_prefix' do
        active_deployment = create(:pages_deployment, project: project, path_prefix: '')
        expect { deleted_deployment.restore }
          .to change { active_deployment.reload.deleted_at }.from(nil).to(Time.zone.now)
      end
    end
  end
end
