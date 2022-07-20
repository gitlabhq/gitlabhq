# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationExportUpload, type: :model do
  subject { described_class.new(relation_export: project_relation_export) }

  let_it_be(:project_relation_export) { create(:project_relation_export) }

  describe 'associations' do
    it { is_expected.to belong_to(:relation_export) }
  end

  it 'stores export file' do
    stub_uploads_object_storage(ImportExportUploader, enabled: false)

    filename = 'labels.tar.gz'
    subject.export_file = fixture_file_upload("spec/fixtures/gitlab/import_export/#{filename}")

    subject.save!

    url = "/uploads/-/system/projects/import_export/relation_export_upload/export_file/#{subject.id}/#{filename}"
    expect(subject.export_file.url).to eq(url)
  end
end
