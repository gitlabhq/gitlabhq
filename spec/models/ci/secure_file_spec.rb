# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SecureFile, factory_default: :keep, feature_category: :mobile_devops do
  let_it_be(:project) { create_default(:project).freeze }
  let(:sample_file) { fixture_file('ci_secure_files/upload-keystore.jks') }

  before do
    stub_ci_secure_file_object_storage
  end

  subject { create(:ci_secure_file, file: CarrierWaveStringFile.new(sample_file)) }

  it { is_expected.to be_a FileStoreMounter }

  it { is_expected.to belong_to(:project).required }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_secure_file, project: create(:project)) }
  end

  describe 'default attributes' do
    before do
      allow(Ci::SecureFileUploader).to receive(:default_store).and_return(5)
    end

    it { expect(described_class.new.file_store).to eq(5) }
    it { expect(described_class.new(file_store: 3).file_store).to eq(3) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:checksum) }
    it { is_expected.to validate_presence_of(:file_store) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project_id) }

    context 'unique filename' do
      let_it_be(:project1) { create(:project) }

      it 'ensures the file name is unique within a given project' do
        file1 = create(:ci_secure_file, project: project1, name: 'file1')
        expect do
          create(:ci_secure_file, project: project1, name: 'file1')
        end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name has already been taken')

        expect(project1.secure_files.where(name: 'file1').count).to be 1
        expect(project1.secure_files.find_by(name: 'file1').id).to eq(file1.id)
      end

      it 'allows duplicate file names in different projects' do
        create(:ci_secure_file, project: project1)
        expect do
          create(:ci_secure_file, project: create(:project))
        end.not_to raise_error
      end
    end
  end

  describe 'ordered scope' do
    it 'returns the newest item first' do
      file1 = create(:ci_secure_file, created_at: 1.week.ago)
      file2 = create(:ci_secure_file, created_at: 2.days.ago)
      file3 = create(:ci_secure_file, created_at: 1.day.ago)

      files = project.secure_files.order_by_created_at

      expect(files[0]).to eq(file3)
      expect(files[1]).to eq(file2)
      expect(files[2]).to eq(file1)
    end
  end

  describe '#checksum' do
    it 'computes SHA256 checksum on the file before encrypted' do
      expect(subject.checksum).to eq(Digest::SHA256.hexdigest(sample_file))
    end
  end

  describe '#checksum_algorithm' do
    it 'returns the configured checksum_algorithm' do
      expect(subject.checksum_algorithm).to eq('sha256')
    end
  end

  describe '#file' do
    it 'returns the saved file' do
      expect(Base64.encode64(subject.file.read)).to eq(Base64.encode64(sample_file))
    end
  end

  describe '#file_extension' do
    it 'returns the extension for the file name' do
      file = build(:ci_secure_file, name: 'file1.cer')
      expect(file.file_extension).to eq('cer')
    end

    it 'returns only the last part of the extension for the file name' do
      file = build(:ci_secure_file, name: 'file1.tar.gz')
      expect(file.file_extension).to eq('gz')
    end

    it 'returns nil if there is no file extension' do
      file = build(:ci_secure_file, name: 'file1')
      expect(file.file_extension).to be nil
    end
  end

  describe '#metadata_parsable?' do
    it 'returns true when the file extension has a supported parser' do
      file = build(:ci_secure_file, name: 'file1.cer')
      expect(file.metadata_parsable?).to be true
    end

    it 'returns false when the file extension does not have a supported parser' do
      file = build(:ci_secure_file, name: 'file1.foo')
      expect(file.metadata_parsable?).to be false
    end
  end

  describe '#metadata_parser' do
    it 'returns an instance of Gitlab::Ci::SecureFiles::Cer when a .cer file is supplied' do
      file = build(:ci_secure_file, name: 'file1.cer')
      expect(file.metadata_parser).to be_an_instance_of(Gitlab::Ci::SecureFiles::Cer)
    end

    it 'returns an instance of Gitlab::Ci::SecureFiles::P12 when a .p12 file is supplied' do
      file = build(:ci_secure_file, name: 'file1.p12')
      expect(file.metadata_parser).to be_an_instance_of(Gitlab::Ci::SecureFiles::P12)
    end

    it 'does not return a metadata_parser when the feature flag is disabled' do
      stub_feature_flags(secure_files_p12_parser: false)
      file = build(:ci_secure_file, name: 'file1.p12')
      expect(file.metadata_parser).not_to be_an_instance_of(Gitlab::Ci::SecureFiles::P12)
    end

    it 'returns an instance of Gitlab::Ci::SecureFiles::MobileProvision when a .mobileprovision file is supplied' do
      file = build(:ci_secure_file, name: 'file1.mobileprovision')
      expect(file.metadata_parser).to be_an_instance_of(Gitlab::Ci::SecureFiles::MobileProvision)
    end

    it 'returns nil when the file type is not supported by any parsers' do
      file = build(:ci_secure_file, name: 'file1.foo')
      expect(file.metadata_parser).to be nil
    end
  end

  describe '#update_metadata!' do
    it 'assigns the expected metadata when a parsable .cer file is supplied' do
      file = create(
        :ci_secure_file,
        name: 'file1.cer',
        file: CarrierWaveStringFile.new(fixture_file('ci_secure_files/sample.cer'))
      )
      file.update_metadata!

      file.reload

      expect(file.expires_at).to eq(DateTime.parse('2023-04-26 19:20:39'))
      expect(file.metadata['id']).to eq('33669367788748363528491290218354043267')
      expect(file.metadata['issuer']['CN']).to eq('Apple Worldwide Developer Relations Certification Authority')
      expect(file.metadata['subject']['OU']).to eq('N7SYAN8PX8')
    end

    it 'assigns the expected metadata when a parsable .p12 file is supplied' do
      file = create(
        :ci_secure_file,
        name: 'file1.p12',
        file: CarrierWaveStringFile.new(fixture_file('ci_secure_files/sample.p12'))
      )
      file.update_metadata!

      file.reload

      expect(file.expires_at).to eq(DateTime.parse('2023-09-21 14:55:59'))
      expect(file.metadata['id']).to eq('75949910542696343243264405377658443914')
      expect(file.metadata['issuer']['CN']).to eq('Apple Worldwide Developer Relations Certification Authority')
      expect(file.metadata['subject']['OU']).to eq('N7SYAN8PX8')
    end

    it 'assigns the expected metadata when a parsable .mobileprovision file is supplied' do
      file = create(
        :ci_secure_file,
        name: 'file1.mobileprovision',
        file: CarrierWaveStringFile.new(fixture_file('ci_secure_files/sample.mobileprovision'))
      )
      file.update_metadata!

      file.reload

      expect(file.expires_at).to eq(DateTime.parse('2023-08-01 23:15:13'))
      expect(file.metadata['id']).to eq('6b9fcce1-b9a9-4b37-b2ce-ec4da2044abf')
      expect(file.metadata['platforms'].first).to eq('iOS')
      expect(file.metadata['app_name']).to eq('iOS Demo')
      expect(file.metadata['app_id']).to eq('match Development com.gitlab.ios-demo')
    end

    it 'logs an error when something goes wrong with the file parsing' do
      corrupt_file = create(:ci_secure_file, name: 'file1.cer', file: CarrierWaveStringFile.new('11111111'))
      message = 'Validation failed: Metadata must be a valid json schema ' \
        '- PEM_read_bio_X509: no start line (Expecting: CERTIFICATE).'
      expect(Gitlab::AppLogger).to receive(:error).with("Secure File Parser Failure (#{corrupt_file.id}): #{message}")
      corrupt_file.update_metadata!
    end
  end

  describe '#local?' do
    it 'returns true when using local storage' do
      secure_file = create(:ci_secure_file)
      secure_file.update!(file_store: ObjectStorage::Store::LOCAL)
      expect(secure_file.local?).to be true
    end

    it 'returns false when using object storage' do
      secure_file = create(:ci_secure_file, file_store: ObjectStorage::Store::REMOTE)
      expect(secure_file.local?).to be false
    end
  end
end
