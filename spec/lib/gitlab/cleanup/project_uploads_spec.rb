# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::ProjectUploads do
  subject { described_class.new(logger: logger) }

  let(:logger) { double(:logger) }

  before do
    allow(logger).to receive(:info).at_least(:once)
    allow(logger).to receive(:debug).at_least(:once)
  end

  describe '#run!' do
    shared_examples_for 'moves the file' do
      shared_examples_for 'a real run' do
        let(:args) { { dry_run: false } }

        it 'moves the file to its proper location' do
          subject.run!(**args)

          expect(File.exist?(path)).to be_falsey
          expect(File.exist?(new_path)).to be_truthy
        end

        it 'logs action as done' do
          expect(logger).to receive(:info).with("Looking for orphaned project uploads to clean up...")
          expect(logger).to receive(:info).with("Did #{action}")

          subject.run!(**args)
        end
      end

      shared_examples_for 'a dry run' do
        it 'does not move the file' do
          subject.run!(**args)

          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(new_path)).to be_falsey
        end

        it 'logs action as able to be done' do
          expect(logger).to receive(:info).with("Looking for orphaned project uploads to clean up. Dry run...")
          expect(logger).to receive(:info).with("Can #{action}")

          subject.run!(**args)
        end
      end

      context 'when dry_run is false' do
        let(:args) { { dry_run: false } }

        it_behaves_like 'a real run'
      end

      context 'when dry_run is nil' do
        let(:args) { { dry_run: nil } }

        it_behaves_like 'a real run'
      end

      context 'when dry_run is true' do
        let(:args) { { dry_run: true } }

        it_behaves_like 'a dry run'
      end

      context 'with dry_run not specified' do
        let(:args) { {} }

        it_behaves_like 'a dry run'
      end
    end

    shared_examples_for 'moves the file to lost and found' do
      let(:action) { "move to lost and found #{path} -> #{new_path}" }

      it_behaves_like 'moves the file'
    end

    shared_examples_for 'fixes the file' do
      let(:action) { "fix #{path} -> #{new_path}" }

      it_behaves_like 'moves the file'
    end

    context 'orphaned project upload file' do
      context 'when an upload record matching the secret and filename is found' do
        context 'when the project is still in legacy storage' do
          let(:orphaned) { create(:upload, :issuable_upload, :with_file, model: create(:project, :legacy_storage)) }
          let(:new_path) { orphaned.absolute_path }
          let(:path) { File.join(FileUploader.root, 'some', 'wrong', 'location', orphaned.path) }

          before do
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.mv(new_path, path)
          end

          it_behaves_like 'fixes the file'
        end

        context 'when the project was moved to hashed storage' do
          let(:orphaned) { create(:upload, :issuable_upload, :with_file) }
          let(:new_path) { orphaned.absolute_path }
          let(:path) { File.join(FileUploader.root, 'some', 'wrong', 'location', orphaned.path) }

          before do
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.mv(new_path, path)
          end

          it_behaves_like 'fixes the file'
        end

        context 'when the project is missing (the upload *record* is an orphan)' do
          let(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let!(:path) { orphaned.absolute_path }
          let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', orphaned.model.full_path, orphaned.path) }

          before do
            orphaned.model.delete
          end

          it_behaves_like 'moves the file to lost and found'
        end

        # We will probably want to add logic (Reschedule background upload) to
        # cover Case 2 in https://gitlab.com/gitlab-org/gitlab-foss/issues/46535#note_75355104
        context 'when the file should be in object storage' do
          context 'when the file otherwise has the correct local path' do
            let!(:orphaned) { create(:upload, :issuable_upload, :object_storage, model: build(:project, :legacy_storage)) }
            let!(:path) { File.join(FileUploader.root, orphaned.model.full_path, orphaned.path) }

            before do
              stub_uploads_object_storage(FileUploader)

              FileUtils.mkdir_p(File.dirname(path))
              FileUtils.touch(path)
            end

            it 'does not move the file' do
              expect(File.exist?(path)).to be_truthy

              subject.run!(dry_run: false)

              expect(File.exist?(path)).to be_truthy
            end
          end

          # E.g. the upload file was orphaned, and then uploads were migrated to
          # object storage
          context 'when the file has the wrong local path' do
            let!(:orphaned) { create(:upload, :issuable_upload, :object_storage, model: build(:project, :legacy_storage)) }
            let!(:path) { File.join(FileUploader.root, 'wrong', orphaned.path) }
            let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', 'wrong', orphaned.path) }

            before do
              stub_uploads_object_storage(FileUploader)

              FileUtils.mkdir_p(File.dirname(path))
              FileUtils.touch(path)
            end

            it_behaves_like 'moves the file to lost and found'
          end
        end
      end

      context 'when a matching upload record can not be found' do
        context 'when the file path fits the known pattern' do
          let!(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let!(:path) { orphaned.absolute_path }
          let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', orphaned.model.full_path, orphaned.path) }

          before do
            orphaned.delete
          end

          it_behaves_like 'moves the file to lost and found'
        end

        context 'when the file path does not fit the known pattern' do
          let!(:invalid_path) { File.join('group', 'file.jpg') }
          let!(:path) { File.join(FileUploader.root, invalid_path) }
          let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', invalid_path) }

          before do
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.touch(path)
          end

          after do
            FileUtils.rm_f(path)
          end

          it_behaves_like 'moves the file to lost and found'
        end
      end
    end

    context 'non-orphaned project upload file' do
      it 'does not move the file' do
        tracked = create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage))
        tracked_path = tracked.absolute_path

        expect(logger).not_to receive(:info).with(/move|fix/i)
        expect(File.exist?(tracked_path)).to be_truthy

        subject.run!(dry_run: false)

        expect(File.exist?(tracked_path)).to be_truthy
      end
    end

    context 'ignorable cases' do
      # Because we aren't concerned about these, and can save a lot of
      # processing time by ignoring them. If we wish to cleanup hashed storage
      # directories, it should simply require removing this test and modifying
      # the find command.
      context 'when the file is already in hashed storage' do
        let(:project) { create(:project) }

        before do
          expect(logger).not_to receive(:info).with(/move|fix/i)
        end

        it 'does not move even an orphan file' do
          orphaned = create(:upload, :issuable_upload, :with_file, model: project)
          path = orphaned.absolute_path
          orphaned.delete

          expect(File.exist?(path)).to be_truthy

          subject.run!(dry_run: false)

          expect(File.exist?(path)).to be_truthy
        end
      end

      it 'does not move any non-project (FileUploader) uploads' do
        paths = []
        orphaned1 = create(:upload, :personal_snippet_upload, :with_file)
        orphaned2 = create(:upload, :namespace_upload, :with_file)
        orphaned3 = create(:upload, :attachment_upload, :with_file)
        orphaned4 = create(:upload, :favicon_upload, :with_file)
        paths << orphaned1.absolute_path
        paths << orphaned2.absolute_path
        paths << orphaned3.absolute_path
        paths << orphaned4.absolute_path
        Upload.delete_all

        expect(logger).not_to receive(:info).with(/move|fix/i)
        paths.each do |path|
          expect(File.exist?(path)).to be_truthy
        end

        subject.run!(dry_run: false)

        paths.each do |path|
          expect(File.exist?(path)).to be_truthy
        end
      end

      it 'does not move any uploads in tmp (which would interfere with ongoing upload activity)' do
        path = File.join(FileUploader.root, 'tmp', 'foo.jpg')
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)

        expect(logger).not_to receive(:info).with(/move|fix/i)
        expect(File.exist?(path)).to be_truthy

        subject.run!(dry_run: false)

        expect(File.exist?(path)).to be_truthy
      end
    end
  end
end
