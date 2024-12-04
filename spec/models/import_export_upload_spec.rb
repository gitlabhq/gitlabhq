# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportExportUpload do
  let(:project) { create(:project) }

  subject(:import_export_upload) { described_class.new(project: project) }

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

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'scopes' do
    let_it_be(:upload1) { create(:import_export_upload, export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz')) }
    let_it_be(:upload2) { create(:import_export_upload, export_file: nil) }
    let_it_be(:upload3) { create(:import_export_upload, export_file: fixture_file_upload('spec/fixtures/project_export.tar.gz'), updated_at: 25.hours.ago) }
    let_it_be(:upload4) { create(:import_export_upload, export_file: nil, updated_at: 2.days.ago) }

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

  context 'ActiveRecord callbacks' do
    let(:after_save_callbacks) { described_class._save_callbacks.select { |cb| cb.kind == :after } }
    let(:after_commit_callbacks) { described_class._commit_callbacks.select { |cb| cb.kind == :after } }

    def find_callback(callbacks, key)
      callbacks.find { |cb| cb.filter == key }
    end

    it 'export file is stored in after_commit callback' do
      expect(find_callback(after_commit_callbacks, :store_export_file!)).to be_present
      expect(find_callback(after_save_callbacks, :store_export_file!)).to be_nil
    end

    it 'import file is stored in after_save callback' do
      expect(find_callback(after_save_callbacks, :store_import_file!)).to be_present
      expect(find_callback(after_commit_callbacks, :store_import_file!)).to be_nil
    end
  end

  describe 'export file' do
    it '#export_file_exists? returns false' do
      expect(subject.export_file_exists?).to be false
    end

    it '#export_archive_exists? returns false' do
      expect(subject.export_archive_exists?).to be false
    end

    context 'with export' do
      let(:project_with_export) { create(:project, :with_export) }

      subject { described_class.with_export_file.find_by(project: project_with_export) }

      it '#export_file_exists? returns true' do
        expect(subject.export_file_exists?).to be true
      end

      it '#export_archive_exists? returns false' do
        expect(subject.export_archive_exists?).to be true
      end

      context 'when object file does not exist' do
        before do
          subject.export_file.file.delete
        end

        it '#export_file_exists? returns true' do
          expect(subject.export_file_exists?).to be true
        end

        it '#export_archive_exists? returns false' do
          expect(subject.export_archive_exists?).to be false
        end
      end

      context 'when checking object existence raises a error' do
        let(:exception) { Excon::Error::Forbidden.new('not allowed') }

        before do
          file = double
          allow(file).to receive(:exists?).and_raise(exception)
          allow(subject).to receive(:carrierwave_export_file).and_return(file)
        end

        it '#export_file_exists? returns true' do
          expect(subject.export_file_exists?).to be true
        end

        it '#export_archive_exists? returns false' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception)
          expect(subject.export_archive_exists?).to be false
        end
      end
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns project_id / group_id' do
      expect(import_export_upload.uploads_sharding_key).to eq(
        project_id: project.id,
        namespace_id: nil
      )
    end
  end
end
