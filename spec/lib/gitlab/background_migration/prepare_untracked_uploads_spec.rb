require 'spec_helper'

# Rollback DB to 10.5 (later than this was originally written for) because it still needs to work.
describe Gitlab::BackgroundMigration::PrepareUntrackedUploads, :sidekiq, :migration, schema: 20180208183958 do
  include MigrationsHelpers::TrackUntrackedUploadsHelpers

  let!(:untracked_files_for_uploads) { table(:untracked_files_for_uploads) }
  let!(:appearances) { table(:appearances) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:routes) { table(:routes) }
  let!(:uploads) { table(:uploads) }
  let!(:users) { table(:users) }

  around do |example|
    # Especially important so the follow-up migration does not get run
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  shared_examples 'prepares the untracked_files_for_uploads table' do
    context 'when files were uploaded before and after hashed storage was enabled' do
      let!(:appearance) { create_or_update_appearance(logo: true, header_logo: true) }
      let!(:user) { create_user(avatar: true) }
      let!(:project1) { create_project(avatar: true) }
      let(:project2) { create_project } # instantiate after enabling hashed_storage

      before do
        # Markdown upload before enabling hashed_storage
        add_markdown_attachment(project1)

        # Markdown upload after enabling hashed_storage
        add_markdown_attachment(project2, hashed_storage: true)
      end

      it 'has a path field long enough for really long paths' do
        described_class.new.perform

        component = 'a' * 255

        long_path = [
          'uploads',
          component, # project.full_path
          component  # filename
        ].flatten.join('/')

        record = untracked_files_for_uploads.create!(path: long_path)
        expect(record.reload.path.size).to eq(519)
      end

      it 'adds unhashed files to the untracked_files_for_uploads table' do
        described_class.new.perform

        expect(untracked_files_for_uploads.count).to eq(5)
      end

      it 'adds files with paths relative to CarrierWave.root' do
        described_class.new.perform
        untracked_files_for_uploads.all.each do |file|
          expect(file.path.start_with?('uploads/')).to be_truthy
        end
      end

      it 'does not add hashed files to the untracked_files_for_uploads table' do
        described_class.new.perform

        hashed_file_path = get_uploads(project2, 'Project').where(uploader: 'FileUploader').first.path
        expect(untracked_files_for_uploads.where("path like '%#{hashed_file_path}%'").exists?).to be_falsey
      end

      it 'correctly schedules the follow-up background migration jobs' do
        described_class.new.perform

        ids = described_class::UntrackedFile.all.order(:id).pluck(:id)
        expect(described_class::FOLLOW_UP_MIGRATION).to be_scheduled_migration(ids.first, ids.last)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end

      # E.g. from a previous failed run of this background migration
      context 'when there is existing data in untracked_files_for_uploads' do
        before do
          described_class.new.perform
        end

        it 'does not error or produce duplicates of existing data' do
          expect do
            described_class.new.perform
          end.not_to change { untracked_files_for_uploads.count }.from(5)
        end
      end

      # E.g. The installation is in use at the time of migration, and someone has
      # just uploaded a file
      context 'when there are files in /uploads/tmp' do
        let(:tmp_file) { Rails.root.join(described_class::ABSOLUTE_UPLOAD_DIR, 'tmp', 'some_file.jpg') }

        before do
          FileUtils.mkdir(File.dirname(tmp_file))
          FileUtils.touch(tmp_file)
        end

        after do
          FileUtils.rm(tmp_file)
        end

        it 'does not add files from /uploads/tmp' do
          described_class.new.perform

          expect(untracked_files_for_uploads.count).to eq(5)
        end
      end

      context 'when the last batch size exactly matches the max batch size' do
        it 'does not raise error' do
          stub_const("#{described_class}::FIND_BATCH_SIZE", 5)

          expect do
            described_class.new.perform
          end.not_to raise_error

          expect(untracked_files_for_uploads.count).to eq(5)
        end
      end
    end
  end

  # If running on Postgres 9.2 (like on CI), this whole context is skipped
  # since we're unable to use ON CONFLICT DO NOTHING or IGNORE.
  context "test bulk insert with ON CONFLICT DO NOTHING or IGNORE", if: described_class.new.send(:can_bulk_insert_and_ignore_duplicates?) do
    it_behaves_like 'prepares the untracked_files_for_uploads table'
  end

  # If running on Postgres 9.2 (like on CI), the stubbed method has no effect.
  #
  # If running on Postgres 9.5+ or MySQL, then this context effectively tests
  # the bulk insert functionality without ON CONFLICT DO NOTHING or IGNORE.
  context 'test bulk insert without ON CONFLICT DO NOTHING or IGNORE' do
    before do
      allow_any_instance_of(described_class).to receive(:postgresql_pre_9_5?).and_return(true)
    end

    it_behaves_like 'prepares the untracked_files_for_uploads table'
  end

  # Very new or lightly-used installations that are running this migration
  # may not have an upload directory because they have no uploads.
  context 'when no files were ever uploaded' do
    it 'deletes the `untracked_files_for_uploads` table (and does not raise error)' do
      background_migration = described_class.new

      expect(background_migration).to receive(:drop_temp_table)

      background_migration.perform
    end
  end
end
