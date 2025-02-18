# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::ExportedRelationsMerger do
  let(:export_job) { create(:project_export_job) }

  let(:shared) { Gitlab::ImportExport::Shared.new(export_job.project) }

  before do
    create(:relation_export_upload,
      relation_export: create(:project_relation_export, relation: 'project', project_export_job: export_job),
      export_file: fixture_file_upload("spec/fixtures/gitlab/import_export/project.tar.gz")
    )

    create(:relation_export_upload,
      relation_export: create(:project_relation_export, relation: 'labels', project_export_job: export_job),
      export_file: fixture_file_upload("spec/fixtures/gitlab/import_export/labels.tar.gz")
    )

    create(:relation_export_upload,
      relation_export: create(:project_relation_export, relation: 'uploads', project_export_job: export_job),
      export_file: fixture_file_upload("spec/fixtures/gitlab/import_export/uploads.tar.gz")
    )
  end

  describe '#save' do
    subject(:service) { described_class.new(export_job: export_job, shared: shared) }

    it 'downloads, extracts, and merges all files into export_path' do
      Dir.mktmpdir do |dirpath|
        allow(shared).to receive(:export_path).and_return(dirpath)

        result = service.save

        expect(result).to eq(true)
        expect(Dir.glob("#{dirpath}/**/*")).to match_array(
          [
            "#{dirpath}/project",
            "#{dirpath}/project/project.json",
            "#{dirpath}/project/labels.ndjson",
            "#{dirpath}/uploads",
            "#{dirpath}/uploads/70edb596c34ad7795baa6a0f0aa03d44",
            "#{dirpath}/uploads/70edb596c34ad7795baa6a0f0aa03d44/file1.txt",
            "#{dirpath}/uploads/c8c93c6f546b002cbce4cb8d05d0dfb8",
            "#{dirpath}/uploads/c8c93c6f546b002cbce4cb8d05d0dfb8/file2.txt"
          ]
        )
      end
    end

    context 'when exception occurs' do
      before do
        create(:project_relation_export, relation: 'releases', project_export_job: export_job)
        create(:project_relation_export, relation: 'issues', project_export_job: export_job)
      end

      it 'registers the exception messages and returns false' do
        Dir.mktmpdir do |dirpath|
          allow(shared).to receive(:export_path).and_return(dirpath)

          result = service.save

          expect(result).to eq(false)
          expect(shared.errors).to match_array(
            [
              /^undefined method `export_file' for nil/,
              /^undefined method `export_file' for nil/
            ]
          )
        end
      end
    end
  end
end
