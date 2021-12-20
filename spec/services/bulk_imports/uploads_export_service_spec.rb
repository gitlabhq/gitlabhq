# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::UploadsExportService do
  let_it_be(:project) { create(:project, avatar: fixture_file_upload('spec/fixtures/rails_sample.png', 'image/png')) }
  let_it_be(:upload) { create(:upload, :with_file, :issuable_upload, uploader: FileUploader, model: project) }
  let_it_be(:export_path) { Dir.mktmpdir }

  subject(:service) { described_class.new(project, export_path) }

  after do
    FileUtils.remove_entry(export_path) if Dir.exist?(export_path)
  end

  describe '#execute' do
    it 'exports project uploads and avatar' do
      subject.execute

      expect(File.exist?(File.join(export_path, 'avatar', 'rails_sample.png'))).to eq(true)
      expect(File.exist?(File.join(export_path, upload.secret, upload.retrieve_uploader.filename))).to eq(true)
    end
  end
end
