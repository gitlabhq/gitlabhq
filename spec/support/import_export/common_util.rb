# frozen_string_literal: true

module ImportExport
  module CommonUtil
    def setup_symlink(tmpdir, symlink_name)
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(tmpdir)

      File.open("#{tmpdir}/test", 'w') { |file| file.write("test") }
      FileUtils.ln_s("#{tmpdir}/test", "#{tmpdir}/#{symlink_name}")
    end
  end
end
