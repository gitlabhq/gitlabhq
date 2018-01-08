require 'rake_helper'

describe 'gitlab:uploads rake tasks' do
  describe 'check' do
    before do
      Rake.application.rake_require 'tasks/gitlab/uploads'
    end

    it 'outputs the integrity check for each uploaded file' do
      uploaded_file = create(:upload)

      expect { run_rake_task('gitlab:uploads:check') }.to output(/Checking file \(#{uploaded_file.id}\): #{Regexp.quote(uploaded_file.absolute_path)}/).to_stdout
    end

    it 'errors out about missing files on the file system' do
      create(:upload)

      expect { run_rake_task('gitlab:uploads:check') }.to output(/File does not exist on the file system/).to_stdout
    end

    it 'errors out about invalid checksum' do
      uploaded_file = create(:upload, path: Rails.root.join('spec/fixtures/banana_sample.gif'))
      uploaded_file.update_column(:checksum, '01a3156db2cf4f67ec823680b40b7302f89ab39179124ad219f94919b8a1769e')

      expect { run_rake_task('gitlab:uploads:check') }.to output(/File checksum \(9e697aa09fe196909813ee36103e34f721fe47a5fdc8aac0e4e4ac47b9b38282\) does not match the one in the database \(#{uploaded_file.checksum}\)/).to_stdout
    end
  end
end
