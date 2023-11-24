# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportUpload, type: :model, feature_category: :importers do
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

  describe 'ActiveRecord callbacks' do
    let(:after_save_callbacks) { described_class._save_callbacks.select { |cb| cb.kind == :after } }
    let(:after_commit_callbacks) { described_class._commit_callbacks.select { |cb| cb.kind == :after } }

    def find_callback(callbacks, key)
      callbacks.find { |cb| cb.filter == key }
    end

    it 'export file is stored in after_commit callback' do
      expect(find_callback(after_commit_callbacks, :store_export_file!)).to be_present
      expect(find_callback(after_save_callbacks, :store_export_file!)).to be_nil
    end
  end
end
