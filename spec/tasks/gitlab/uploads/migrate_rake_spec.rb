require 'rake_helper'

describe 'gitlab:uploads:migrate rake tasks' do
  let(:model_class) { nil }
  let(:uploader_class) { nil }
  let(:mounted_as) { nil }
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

  context "for AvatarUploader" do
    let(:uploader_class) { AvatarUploader }
    let(:mounted_as) { :avatar }

    context "for Project" do
      let(:model_class) { Project }
      let!(:projects) { create_list(:project, 10, :with_avatar) }

      it_behaves_like 'enqueue jobs in batch', batch: 4

      context 'Upload has store = nil' do
        before do
          Upload.where(model: projects).update_all(store: nil)
        end

        it_behaves_like 'enqueue jobs in batch', batch: 4
      end
    end

    context "for Group" do
      let(:model_class) { Group }

      before do
        create_list(:group, 10, :with_avatar)
      end

      it_behaves_like 'enqueue jobs in batch', batch: 4
    end

    context "for User" do
      let(:model_class) { User }

      before do
        create_list(:user, 10, :with_avatar)
      end

      it_behaves_like 'enqueue jobs in batch', batch: 4
    end
  end

  context "for AttachmentUploader" do
    let(:uploader_class) { AttachmentUploader }

    context "for Note" do
      let(:model_class) { Note }
      let(:mounted_as) { :attachment }

      before do
        create_list(:note, 10, :with_attachment)
      end

      it_behaves_like 'enqueue jobs in batch', batch: 4
    end

    context "for Appearance" do
      let(:model_class) { Appearance }
      let(:mounted_as) { :logo }

      before do
        create(:appearance, :with_logos)
      end

      %i(logo header_logo).each do |mount|
        it_behaves_like 'enqueue jobs in batch', batch: 1 do
          let(:mounted_as) { mount }
        end
      end
    end
  end

  context "for FileUploader" do
    let(:uploader_class) { FileUploader }
    let(:model_class) { Project }

    before do
      create_list(:project, 10) do |model|
        uploader_class.new(model)
          .store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
      end
    end

    it_behaves_like 'enqueue jobs in batch', batch: 4
  end

  context "for PersonalFileUploader" do
    let(:uploader_class) { PersonalFileUploader }
    let(:model_class) { PersonalSnippet }

    before do
      create_list(:personal_snippet, 10) do |model|
        uploader_class.new(model)
          .store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
      end
    end

    it_behaves_like 'enqueue jobs in batch', batch: 4
  end

  context "for NamespaceFileUploader" do
    let(:uploader_class) { NamespaceFileUploader }
    let(:model_class) { Snippet }

    before do
      create_list(:snippet, 10) do |model|
        uploader_class.new(model)
          .store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
      end
    end

    it_behaves_like 'enqueue jobs in batch', batch: 4
  end
end
