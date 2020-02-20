# frozen_string_literal: true

require 'spec_helper'

describe Groups::ImportExport::ImportService do
  describe '#execute' do
    let(:user) { create(:admin) }
    let(:group) { create(:group) }
    let(:service) { described_class.new(group: group, user: user) }
    let(:import_file) { fixture_file_upload('spec/fixtures/group_export.tar.gz') }

    subject { service.execute }

    before do
      ImportExportUpload.create(group: group, import_file: import_file)
    end

    context 'when user has correct permissions' do
      it 'imports group structure successfully' do
        expect(subject).to be_truthy
      end

      it 'removes import file' do
        subject

        expect(group.import_export_upload.import_file.file).to be_nil
      end
    end

    context 'when user does not have correct permissions' do
      let(:user) { create(:user) }

      it 'raises exception' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
