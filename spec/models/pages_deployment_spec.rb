# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDeployment do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:ci_build).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_numericality_of(:size).only_integer.is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:file_store).in_array(ObjectStorage::SUPPORTED_STORES) }

    it 'is valid when created from the factory' do
      expect(create(:pages_deployment)).to be_valid
    end
  end

  describe 'default for file_store' do
    it 'uses local store when object storage is not enabled' do
      expect(build(:pages_deployment).file_store).to eq(ObjectStorage::Store::LOCAL)
    end

    it 'uses remote store when object storage is enabled' do
      stub_pages_object_storage(::Pages::DeploymentUploader)

      expect(build(:pages_deployment).file_store).to eq(ObjectStorage::Store::REMOTE)
    end
  end

  it 'saves size along with the file' do
    deployment = create(:pages_deployment)
    expect(deployment.size).to eq(deployment.file.size)
  end
end
