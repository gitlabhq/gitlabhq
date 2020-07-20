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
end
