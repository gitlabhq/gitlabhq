# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Terraform::StateMigrationHelper do
  before do
    stub_terraform_state_object_storage
  end

  describe '.migrate_to_remote_storage' do
    let!(:local_version) { create(:terraform_state_version, file_store: Terraform::StateUploader::Store::LOCAL) }

    subject { described_class.migrate_to_remote_storage }

    it 'migrates remote files to remote storage' do
      subject

      expect(local_version.reload.file_store).to eq(Terraform::StateUploader::Store::REMOTE)
    end
  end
end
