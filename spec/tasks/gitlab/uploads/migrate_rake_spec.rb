require 'rake_helper'

describe 'gitlab:uploads:migrate rake tasks' do
  let!(:projects) { create_list(:project, 10, :with_avatar) }
  let(:model_class) { Project }
  let(:uploader_class) { AvatarUploader }
  let(:mounted_as) { :avatar }
  let(:batch_size) { 3 }

  before do
    stub_env('BATCH', batch_size.to_s)
    stub_uploads_object_storage(uploader_class)
    Rake.application.rake_require 'tasks/gitlab/uploads/migrate'

    allow(ObjectStorage::MigrateUploadsWorker).to receive(:perform_async)
  end

  def run
    args = [uploader_class.to_s, model_class.to_s, mounted_as].compact
    run_rake_task("gitlab:uploads:migrate", *args)
  end

  shared_examples 'enqueue jobs in batch' do |batch:|
    it do
      expect(ObjectStorage::MigrateUploadsWorker)
        .to receive(:perform_async).exactly(batch).times
              .and_return("A fake job.")

      run
    end
  end

  context 'Upload has store = nil' do
    before do
      Upload.where(model: projects.first(5)).update_all(store: nil)
    end

    it_behaves_like 'enqueue jobs in batch', batch: 4
  end
end
