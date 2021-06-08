# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportExportUpload do
  subject { described_class.new(project: create(:project)) }

  shared_examples 'stores the Import/Export file' do |method|
    it 'stores the import file' do
      subject.public_send("#{method}=", fixture_file_upload('spec/fixtures/project_export.tar.gz'))

      subject.save!

      url = "/uploads/-/system/import_export_upload/#{method}/#{subject.id}/project_export.tar.gz"

      expect(subject.public_send(method).url).to eq(url)
    end
  end

  context 'import' do
    it_behaves_like 'stores the Import/Export file', :import_file
  end

  context 'export' do
    it_behaves_like 'stores the Import/Export file', :export_file
  end

  describe 'scopes' do
    let_it_be(:upload1) { create(:import_export_upload, export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')) }
    let_it_be(:upload2) { create(:import_export_upload) }
    let_it_be(:upload3) { create(:import_export_upload, export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz'), updated_at: 25.hours.ago) }
    let_it_be(:upload4) { create(:import_export_upload, updated_at: 2.days.ago) }

    describe '.with_export_file' do
      it 'returns uploads with export file' do
        expect(described_class.with_export_file).to contain_exactly(upload1, upload3)
      end
    end

    describe '.updated_before' do
      it 'returns uploads for a specified date' do
        expect(described_class.updated_before(24.hours.ago)).to contain_exactly(upload3, upload4)
      end
    end
  end
end
