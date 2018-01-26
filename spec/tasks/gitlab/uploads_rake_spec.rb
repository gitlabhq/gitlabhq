require 'rake_helper'

describe 'gitlab:uploads rake tasks' do
  describe 'check' do
    let!(:upload) { create(:upload, path: Rails.root.join('spec/fixtures/banana_sample.gif')) }

    before do
      Rake.application.rake_require 'tasks/gitlab/uploads/check'
    end

    it 'outputs the integrity check for each uploaded file' do
      expect { run_rake_task('gitlab:uploads:check') }.to output(/Checking file \(#{upload.id}\): #{Regexp.quote(upload.absolute_path)}/).to_stdout
    end

    it 'errors out about missing files on the file system' do
      create(:upload)

      expect { run_rake_task('gitlab:uploads:check') }.to output(/File does not exist on the file system/).to_stdout
    end

    it 'errors out about invalid checksum' do
      upload.update_column(:checksum, '01a3156db2cf4f67ec823680b40b7302f89ab39179124ad219f94919b8a1769e')

      expect { run_rake_task('gitlab:uploads:check') }.to output(/File checksum \(9e697aa09fe196909813ee36103e34f721fe47a5fdc8aac0e4e4ac47b9b38282\) does not match the one in the database \(#{upload.checksum}\)/).to_stdout
    end
  end

  describe 'migrate' do
    let!(:projects) { create_list(:project, 10, :with_avatar) }
    let(:model_class) { Project }
    let(:uploader_class) { AvatarUploader }
    let(:mounted_as) { :avatar }
    let(:batch_size) { 3 }

    before do
      stub_env('BATCH', batch_size.to_s)
      stub_uploads_object_storage(uploader_class)
      Rake.application.rake_require 'tasks/gitlab/uploads/migrate'
    end

    def run
      args = [uploader_class.to_s, model_class.to_s, mounted_as].compact
      run_rake_task("gitlab:uploads:migrate", *args)
    end

    shared_examples 'outputs correctly' do |success: 0, failures: 0|
      total = success + failures

      it 'outputs the results for each batch' do
        batch_count = [batch_size, total].min

        expect { run }.to output(%r{Migrated #{batch_count}/#{batch_count} files}).to_stdout
      end if success > 0 # rubocop:disable Style/MultilineIfModifier

      it 'outputs the results for the task' do
        expect { run }.to output(%r{Migrated #{success}/#{total} files}).to_stdout
      end if success > 0 # rubocop:disable Style/MultilineIfModifier

      it 'outputs upload failures' do
        expect { run }.to output(/Error .* I am a teapot/).to_stdout
      end if failures > 0 # rubocop:disable Style/MultilineIfModifier
    end

    it_behaves_like 'outputs correctly', success: 10

    it 'migrates files' do
      run

      aggregate_failures do
        projects.each do |project|
          expect(project.reload.avatar.upload.local?).to be_falsey
        end
      end
    end

    context 'migration is unsuccessful' do
      before do
        allow_any_instance_of(ObjectStorage::Concern).to receive(:migrate!).and_raise(CarrierWave::UploadError, "I am a teapot.")
      end

      it_behaves_like 'outputs correctly', failures: 10
    end
  end
end
