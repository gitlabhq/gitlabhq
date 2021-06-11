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

      allow(Gitlab::ImportExport).to receive(:export_path) { export_path }
    end

    def setup_reader(reader)
      if reader == :ndjson_reader && Feature.enabled?(:project_import_ndjson, default_enabled: true)
        allow_any_instance_of(Gitlab::ImportExport::Json::LegacyReader::File).to receive(:exist?).and_return(false)
        allow_any_instance_of(Gitlab::ImportExport::Json::NdjsonReader).to receive(:exist?).and_return(true)
      else
        allow_any_instance_of(Gitlab::ImportExport::Json::LegacyReader::File).to receive(:exist?).and_return(true)
        allow_any_instance_of(Gitlab::ImportExport::Json::NdjsonReader).to receive(:exist?).and_return(false)
      end
    end

    def fixtures_path
      "spec/fixtures/lib/gitlab/import_export"
    end

    def test_tmp_path
      "tmp/tests/gitlab-test/import_export"
    end

    def get_json(path, exportable_path, key, ndjson_enabled)
      if ndjson_enabled
        json = if key == :projects
                 consume_attributes(path, exportable_path)
               else
                 consume_relations(path, exportable_path, key)
               end
      else
        json = project_json(path)
        json = json[key.to_s] unless key == :projects
      end

      json
    end

    def restore_then_save_project(project, import_path:, export_path:)
      project_restorer = get_project_restorer(project, import_path)
      project_saver = get_project_saver(project, export_path)

      project_restorer.restore && project_saver.save
    end

    def get_project_restorer(project, import_path)
      Gitlab::ImportExport::Project::TreeRestorer.new(
        user: project.creator, shared: get_shared_env(path: import_path), project: project
      )
    end

    def get_project_saver(project, export_path)
      Gitlab::ImportExport::Project::TreeSaver.new(
        project: project, current_user: project.creator, shared: get_shared_env(path: export_path)
      )
    end

    def get_shared_env(path:, logger: nil)
      logger ||= double(info: true, warn: true, error: true)

      instance_double(Gitlab::ImportExport::Shared).tap do |shared|
        allow(shared).to receive(:export_path).and_return(path)
        allow(shared).to receive(:logger).and_return(logger)
      end
    end

    def consume_attributes(dir_path, exportable_path)
      path = File.join(dir_path, "#{exportable_path}.json")
      return unless File.exist?(path)

      ActiveSupport::JSON.decode(IO.read(path))
    end

    def consume_relations(dir_path, exportable_path, key)
      path = File.join(dir_path, exportable_path, "#{key}.ndjson")
      return unless File.exist?(path)

      relations = []

      File.foreach(path) do |line|
        json = ActiveSupport::JSON.decode(line)
        relations << json
      end

      key == :project_feature ? relations.first : relations.flatten
    end

    def project_json(filename)
      ActiveSupport::JSON.decode(IO.read(filename))
    end
  end
end
