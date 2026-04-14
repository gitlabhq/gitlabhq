# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WithUploads, feature_category: :groups_and_projects do
  describe '#uploads_cascade_deleted_on_destroy?' do
    subject { model_object.send(:uploads_cascade_deleted_on_destroy?) }

    context 'when uploads_sharding_key is empty' do
      let(:model_object) { create(:appearance) }

      it { is_expected.to be false }
    end

    context 'when uploads_sharding_key contains namespace_id' do
      let(:model_object) { create(:group) }

      it { is_expected.to be true }
    end

    context 'when uploads_sharding_key contains project_id' do
      let_it_be(:model_object) { create(:project) }

      it { is_expected.to be true }
    end

    context 'when uploads_sharding_key contains only organization_id' do
      let(:model_object) { create(:user) }

      it { is_expected.to be true }
    end

    context 'when model does not respond to uploads_sharding_key' do
      let(:model_object) do
        klass = Class.new(ApplicationRecord) do
          self.table_name = 'appearances'
          include WithUploads
        end

        klass.first || klass.create!(title: '', description: '')
      end

      it { is_expected.to be false }
    end
  end

  describe '#capture_mounted_remote_uploaders' do
    before do
      stub_uploads_object_storage(AvatarUploader)
    end

    context 'when uploads_cascade_deleted_on_destroy? is false' do
      let(:model_object) { create(:appearance) }

      it 'does not query uploads or register after_commit hook' do
        expect(model_object).not_to receive(:run_after_commit)

        model_object.send(:capture_mounted_remote_uploaders)
      end
    end

    context 'when uploads_cascade_deleted_on_destroy? is true' do
      let_it_be(:project) { create(:project) }

      context 'when there are no uploads at all' do
        it 'does not register an after_commit hook' do
          expect(project).not_to receive(:run_after_commit)

          project.send(:capture_mounted_remote_uploaders)
        end
      end

      context 'when there are only FILE_UPLOADERS uploads stored remotely' do
        before do
          create(:upload, :object_storage, :issuable_upload, model: project)
        end

        it 'does not capture them (they are handled by fast_destroy)' do
          expect(project).not_to receive(:run_after_commit)

          project.send(:capture_mounted_remote_uploaders)
        end
      end

      context 'when there are only local mounted uploads' do
        before do
          create(:upload, model: project, uploader: 'AvatarUploader',
            mount_point: :avatar, store: ObjectStorage::Store::LOCAL)
        end

        it 'does not register an after_commit hook' do
          expect(project).not_to receive(:run_after_commit)

          project.send(:capture_mounted_remote_uploaders)
        end
      end

      context 'when there are remote mounted uploads with nil mount_point' do
        let!(:remote_upload) do
          create(:upload, :object_storage, model: project,
            uploader: 'AvatarUploader', mount_point: nil)
        end

        it 'passes nil to retrieve_uploader' do
          expect(project).to receive(:run_after_commit).and_yield

          uploader_double = instance_double(AvatarUploader)
          file_double = instance_double(CarrierWave::Storage::Fog::File)

          allow_any_instance_of(Upload).to receive(:retrieve_uploader).with(nil).and_return(uploader_double) # rubocop:disable RSpec/AnyInstanceOf -- method is called on freshly loaded records from DB
          expect(uploader_double).to receive(:file).and_return(file_double)
          expect(file_double).to receive(:delete)

          project.send(:capture_mounted_remote_uploaders)
        end
      end

      context 'when there are remote mounted uploads' do
        let!(:remote_upload) do
          create(:upload, :object_storage, model: project,
            uploader: 'AvatarUploader', mount_point: :avatar)
        end

        it 'snapshots uploaders and schedules remote file deletion after commit' do
          expect(project).to receive(:run_after_commit).and_yield

          uploader_double = instance_double(AvatarUploader)
          file_double = instance_double(CarrierWave::Storage::Fog::File)

          allow_any_instance_of(Upload).to receive(:retrieve_uploader).with(:avatar).and_return(uploader_double) # rubocop:disable RSpec/AnyInstanceOf -- method is called on freshly loaded records from DB, not the local variable
          expect(uploader_double).to receive(:file).and_return(file_double)
          expect(file_double).to receive(:delete)

          project.send(:capture_mounted_remote_uploaders)
        end

        it 'tracks exceptions without re-raising when remote deletion fails' do
          expect(project).to receive(:run_after_commit).and_yield

          uploader_double = instance_double(AvatarUploader)
          allow_any_instance_of(Upload).to receive(:retrieve_uploader).with(:avatar).and_return(uploader_double) # rubocop:disable RSpec/AnyInstanceOf -- method is called on freshly loaded records from DB, not the local variable
          expect(uploader_double).to receive(:file).and_raise(StandardError, 'storage error')
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(StandardError))

          expect { project.send(:capture_mounted_remote_uploaders) }.not_to raise_error
        end

        it 'does not delete when uploader file is nil' do
          expect(project).to receive(:run_after_commit).and_yield

          uploader_double = instance_double(AvatarUploader)
          allow_any_instance_of(Upload).to receive(:retrieve_uploader).with(:avatar).and_return(uploader_double) # rubocop:disable RSpec/AnyInstanceOf -- method is called on freshly loaded records from DB, not the local variable
          expect(uploader_double).to receive(:file).and_return(nil)

          expect { project.send(:capture_mounted_remote_uploaders) }.not_to raise_error
        end
      end
    end
  end

  describe 'before_destroy callback registration' do
    it 'fires capture_mounted_remote_uploaders on destroy' do
      project = create(:project)

      expect(project).to receive(:capture_mounted_remote_uploaders)

      project.run_callbacks(:destroy) { false }
    end

    it 'registers capture_mounted_remote_uploaders before the fast_destroy callback' do
      before_destroy_callbacks = Project._destroy_callbacks.select { |cb| cb.kind == :before }
      callback_filters = before_destroy_callbacks.map(&:filter)

      capture_index = callback_filters.index(:capture_mounted_remote_uploaders)
      fast_destroy_indices = before_destroy_callbacks.each_index.select do |i|
        cb = before_destroy_callbacks[i]
        cb.filter.is_a?(Proc) &&
          cb.filter.source_location&.first&.include?('fast_destroy_all.rb')
      end
      fast_destroy_index = fast_destroy_indices.find { |i| i > capture_index }

      expect(capture_index).not_to be_nil, 'capture_mounted_remote_uploaders callback not found'
      expect(fast_destroy_index).not_to be_nil,
        'No fast_destroy callback found after capture_mounted_remote_uploaders'
      expect(capture_index).to be < fast_destroy_index,
        'Expected capture_mounted_remote_uploaders to run before the fast_destroy callback'
    end
  end

  describe 'end-to-end destroy with remote mounted uploads' do
    let(:group) { create(:group) }

    before do
      stub_uploads_object_storage(AvatarUploader)
    end

    it 'deletes remote files after the model is destroyed' do
      group.avatar.migrate!(ObjectStorage::Store::REMOTE) if group.avatar.present?

      # Create a remote mounted upload for the group
      create(:upload, :object_storage, model: group,
        uploader: 'AvatarUploader', mount_point: :avatar)

      fog_file_double = instance_double(CarrierWave::Storage::Fog::File)
      allow_any_instance_of(AvatarUploader).to receive(:file).and_return(fog_file_double) # rubocop:disable RSpec/AnyInstanceOf -- need to intercept dynamically built uploader

      expect(fog_file_double).to receive(:delete)

      group.destroy!
    end

    context 'when model has organization_id-only sharding key' do
      let(:user) { create(:user) }

      it 'attempts remote file cleanup via capture_mounted_remote_uploaders' do
        create(:upload, :object_storage, model: user,
          uploader: 'AvatarUploader', mount_point: :avatar)

        expect(user.send(:uploads_cascade_deleted_on_destroy?)).to be true
        expect(user.uploads.where.not(uploader: WithUploads::FILE_UPLOADERS)).to exist

        expect(user).to receive(:run_after_commit).and_yield

        uploader_double = instance_double(AvatarUploader)
        file_double = instance_double(CarrierWave::Storage::Fog::File)

        allow_any_instance_of(Upload).to receive(:retrieve_uploader).with(:avatar).and_return(uploader_double) # rubocop:disable RSpec/AnyInstanceOf -- method is called on freshly loaded records from DB
        expect(uploader_double).to receive(:file).and_return(file_double)
        expect(file_double).to receive(:delete)

        user.send(:capture_mounted_remote_uploaders)
      end
    end

    context 'when a model with organization_id sharding key and a mounted remote uploader ' \
      'is cascade-deleted via organization destroy' do
      let(:organization) { create(:organization) }
      let(:abuse_report) { create(:abuse_report, organization: organization) }

      before do
        stub_uploads_object_storage(AttachmentUploader)
      end

      it 'does not delete remote files because DB cascade bypasses Rails callbacks' do
        create(:upload, :object_storage, :attachment_upload,
          model: abuse_report, uploader: 'AttachmentUploader', mount_point: :screenshot)

        fog_file_double = instance_double(CarrierWave::Storage::Fog::File)
        allow_any_instance_of(AttachmentUploader).to receive(:file).and_return(fog_file_double) # rubocop:disable RSpec/AnyInstanceOf -- need to intercept dynamically built uploader

        expect(fog_file_double).not_to receive(:delete)

        organization.destroy!
      end
    end

    context 'when a model with organization_id sharding key is destroyed directly via Rails' do
      let(:abuse_report) { create(:abuse_report) }

      before do
        stub_uploads_object_storage(AttachmentUploader)
      end

      it 'deletes remote files after the model is destroyed' do
        create(:upload, :object_storage, :attachment_upload,
          model: abuse_report, uploader: 'AttachmentUploader', mount_point: :screenshot)

        fog_file_double = instance_double(CarrierWave::Storage::Fog::File)
        allow_any_instance_of(AttachmentUploader).to receive(:file).and_return(fog_file_double) # rubocop:disable RSpec/AnyInstanceOf -- need to intercept dynamically built uploader

        expect(fog_file_double).to receive(:delete)

        abuse_report.destroy!
      end
    end
  end
end
