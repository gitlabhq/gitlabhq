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

  describe '#sweep_mounted_uploads' do
    let(:user) { create(:user, :with_avatar) }

    def mounted_uploads
      Upload.for_model_type_and_id('User', user.id)
    end

    context 'when the file is already gone' do
      let(:absolute_path) { user.avatar.path }

      before do
        FileUtils.rm_f(absolute_path)
      end

      it 'removes the upload row carrierwave left behind without deleting files', :aggregate_failures do
        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        expect { user.destroy! }.to change { mounted_uploads.count }.from(1).to(0)
      end
    end

    context 'when sweep_orphaned_mounted_uploads is disabled' do
      before do
        stub_feature_flags(sweep_orphaned_mounted_uploads: false)
        FileUtils.rm_f(user.avatar.path)
      end

      it 'leaves the row carrierwave skipped behind', :aggregate_failures do
        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        expect { user.destroy! }.not_to change { mounted_uploads.count }
        expect(mounted_uploads.count).to eq(1)
      end
    end

    context 'when the file is still present' do
      it 'leaves the cleanup to carrierwave', :aggregate_failures do
        absolute_path = user.avatar.path

        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        expect { user.destroy! }
          .to change { mounted_uploads.count }.from(1).to(0)
          .and change { File.exist?(absolute_path) }.from(true).to(false)
      end
    end

    context 'when the upload is stored remotely and the object is gone' do
      before do
        stub_uploads_object_storage(AvatarUploader)
        user.avatar.migrate!(ObjectStorage::Store::REMOTE)
        user.avatar.file.delete
      end

      it 'removes the upload row without touching object storage', :aggregate_failures do
        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        expect { user.destroy! }.to change { mounted_uploads.count }.from(1).to(0)
      end
    end

    context 'when the model has no uploads' do
      let(:user) { create(:user) }

      it 'does not schedule any file deletion' do
        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        user.destroy!
      end
    end

    context 'when a model mounts several uploaders and only one file is gone' do
      let(:appearance) { create(:appearance, :with_logo, :with_pwa_icon) }

      def appearance_uploads
        Upload.for_model_type_and_id('Appearance', appearance.id)
      end

      it 'sweeps the row carrierwave skipped and leaves the other file to carrierwave', :aggregate_failures do
        icon_path = appearance.pwa_icon.path

        FileUtils.rm_f(appearance.logo.path)

        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        expect { appearance.destroy! }
          .to change { appearance_uploads.count }.from(2).to(0)
          .and change { File.exist?(icon_path) }.from(true).to(false)
      end
    end

    context 'when the model also has a FileUploader upload' do
      let(:snippet) { create(:personal_snippet) }
      let!(:file_upload) { create(:upload, :personal_snippet_upload, :with_file, model: snippet) }

      def snippet_uploads
        Upload.for_model_type_and_id(snippet.class.polymorphic_name, snippet.id)
      end

      # A single scheduling means use_fast_destroy handled the row and the sweep
      # left it alone; a second would mean both paths claimed it.
      it 'leaves those rows to use_fast_destroy' do
        expect(DeleteStoredFilesWorker).to receive(:perform_async)
          .with('Uploads::Local', [file_upload.absolute_path]).once

        expect { snippet.destroy! }.to change { snippet_uploads.count }.from(1).to(0)
      end
    end

    # Project mounts avatar before including AfterCommitQueue, so unlike the
    # models above its sweep runs first. The FK cascade has already removed the
    # rows by then, so there is nothing left to sweep.
    context 'when the sharding key FK cascade-deletes the rows first' do
      let(:project) { create(:project, :with_avatar) }

      it 'leaves the cleanup to carrierwave' do
        absolute_path = project.avatar.path

        expect(DeleteStoredFilesWorker).not_to receive(:perform_async)

        expect { project.destroy! }.to change { File.exist?(absolute_path) }.from(true).to(false)
      end
    end
  end

  describe 'before_destroy callback registration' do
    it 'fires capture_mounted_remote_uploaders on destroy' do
      project = create(:project)

      expect(project).to receive(:capture_mounted_remote_uploaders)

      project.run_callbacks(:destroy) { false }
    end

    it 'fires sweep_mounted_uploads on destroy' do
      user = create(:user)

      expect(user).to receive(:sweep_mounted_uploads)

      user.run_callbacks(:destroy) { false }
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

  describe 'after_commit callback order' do
    # sweep_mounted_uploads runs from the AfterCommitQueue, so it has to fire
    # after carrierwave's destroy hooks. Reversed, it would delete the Upload
    # rows carrierwave still needs to locate the files.
    #
    # Nothing in the models enforces this. `mount_uploader` and AfterCommitQueue
    # each register an after_commit callback, and because
    # run_after_transaction_callbacks_in_order_defined is false
    # (config/application.rb) they run LIFO -- so whichever is included first
    # wins. Reordering two `include`s would silently invert it, and so would
    # adopting Rails' new default of `true`, which flips every model at once.
    # This spec is the only thing that will notice.
    # Project is the one model that inverts the order, so it is asserted
    # separately below rather than excluded silently.
    inverted = [Project].freeze

    def commit_callback_execution_order(model)
      filters = model._commit_callbacks.map(&:filter)

      ActiveRecord.run_after_transaction_callbacks_in_order_defined ? filters : filters.reverse
    end

    # Derived rather than hardcoded so a new WithUploads model that mounts an
    # uploader is covered the day it is added.
    def models_with_mounted_uploaders
      ApplicationRecord.descendants.select do |model|
        !model.abstract_class? && model.include?(WithUploads) && model.try(:uploaders).present?
      end
    end

    # carrierwave registers after_commit :"remove_#{column}!" per mount, so the
    # mount list gives the exact callback names.
    def carrierwave_destroy_hooks(model)
      model.uploaders.keys.map { |column| :"remove_#{column}!" }
    end

    it 'runs carrierwave cleanup before the after_commit queue', :eager_load, :aggregate_failures do
      models = models_with_mounted_uploaders - inverted
      expect(models).not_to be_empty, 'no WithUploads models with mounted uploaders were discovered'

      models.each do |model|
        execution_order = commit_callback_execution_order(model)
        hook_indices = carrierwave_destroy_hooks(model).filter_map { |hook| execution_order.index(hook) }
        queue_index = execution_order.index(:_run_after_commit_queue)

        expect(hook_indices).not_to be_empty, "no carrierwave remove_*! callback found on #{model}"
        expect(queue_index).not_to be_nil, "AfterCommitQueue callback not found on #{model}"
        expect(hook_indices.max).to be < queue_index,
          "Expected #{model} to run carrierwave cleanup before sweep_mounted_uploads runs from the " \
            'after_commit queue'
      end
    end

    # Project includes Avatarable (and so mounts avatar) before AfterCommitQueue,
    # which puts its sweep first. Harmless only because the sharding key FK
    # cascade clears the rows inside the transaction. If you fix the include
    # order, move Project into the list above rather than reverting this.
    describe 'Project' do
      it 'runs the after_commit queue before carrierwave cleanup' do
        execution_order = commit_callback_execution_order(Project)
        carrierwave_index = execution_order.index(:remove_avatar!)
        queue_index = execution_order.index(:_run_after_commit_queue)

        expect(queue_index).to be < carrierwave_index
      end
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
