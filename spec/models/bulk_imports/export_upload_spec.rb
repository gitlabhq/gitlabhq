# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportUpload do
  subject { described_class.new(export: create(:bulk_import_export)) }

  describe 'associations' do
    it { is_expected.to belong_to(:export) }
  end

  it 'stores export file' do
    method = 'export_file'
    filename = 'labels.ndjson.gz'

    subject.public_send("#{method}=", fixture_file_upload("spec/fixtures/bulk_imports/gz/#{filename}"))
    subject.save!

    url = "/uploads/-/system/bulk_imports/export_upload/export_file/#{subject.id}/#{filename}"

    expect(subject.public_send(method).url).to eq(url)
  end
end
