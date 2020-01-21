# frozen_string_literal: true

module ImportExport
  module CommonUtil
    def setup_symlink(tmpdir, symlink_name)
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(tmpdir)
      end

      File.open("#{tmpdir}/test", 'w') { |file| file.write("test") }
      FileUtils.ln_s("#{tmpdir}/test", "#{tmpdir}/#{symlink_name}")
    end

    def setup_import_export_config(name, prefix = nil)
      export_path = [prefix, 'spec', 'fixtures', 'lib', 'gitlab', 'import_export', name].compact
      export_path = File.join(*export_path)

      allow_any_instance_of(Gitlab::ImportExport).to receive(:export_path) { export_path }
    end
  end
end
