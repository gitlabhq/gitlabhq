# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::LfsPointers::LfsDownloadService do
  include StubRequests

  let_it_be(:project) { create(:project) }

  let(:lfs_content) { SecureRandom.random_bytes(10) }
  let(:oid) { Digest::SHA256.hexdigest(lfs_content) }
  let(:download_link) { "http://gitlab.com/#{oid}" }
  let(:size) { lfs_content.size }
  let(:lfs_object) { LfsDownloadObject.new(oid: oid, size: size, link: download_link) }
  let(:local_request_setting) { false }

  subject { described_class.new(project, lfs_object) }

  before_all do
    ApplicationSetting.create_from_defaults
  end

  before do
    stub_application_setting(allow_local_requests_from_web_hooks_and_services: local_request_setting)
    allow(project).to receive(:lfs_enabled?).and_return(true)
  end

  shared_examples 'lfs temporal file is removed' do
    it do
      subject.execute

      expect(File.exist?(subject.send(:tmp_filename))).to be false
    end
  end

  shared_examples 'no lfs object is created' do
    it do
      expect { subject.execute }.not_to change { LfsObject.count }
    end

    it 'returns error result' do
      expect(subject.execute[:status]).to eq :error
    end

    it 'an error is logged' do
      expect(subject).to receive(:log_error)

      subject.execute
    end

    it_behaves_like 'lfs temporal file is removed'
  end

  shared_examples 'lfs object is created' do
    it 'creates and associate the LFS object to project' do
      expect(subject).to receive(:download_and_save_file!).and_call_original

      expect { subject.execute }.to change { LfsObject.count }.by(1)
      expect(LfsObject.first.projects).to include(project)
    end

    it 'returns success result' do
      expect(subject.execute[:status]).to eq :success
    end

    it_behaves_like 'lfs temporal file is removed'
  end

  describe '#execute' do
    context 'when file download succeeds' do
      before do
        stub_full_request(download_link).to_return(body: lfs_content)
      end

      it_behaves_like 'lfs object is created'

      it 'has the same oid' do
        subject.execute

        expect(LfsObject.first.oid).to eq oid
      end

      it 'has the same size' do
        subject.execute

        expect(LfsObject.first.size).to eq size
      end

      it 'stores the content' do
        subject.execute

        expect(File.binread(LfsObject.first.file.file.file)).to eq lfs_content
      end
    end

    context 'when file download fails' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(code: 500, 'success?' => false)
      end

      it_behaves_like 'no lfs object is created'

      it 'raise StandardError exception' do
        expect(subject).to receive(:download_and_save_file!).and_raise(StandardError)

        subject.execute
      end
    end

    context 'when downloaded lfs file has a different size' do
      let(:size) { 1 }

      before do
        stub_full_request(download_link).to_return(body: lfs_content)
      end

      it_behaves_like 'no lfs object is created'

      it 'raise SizeError exception' do
        expect(subject).to receive(:download_and_save_file!).and_raise(described_class::SizeError)

        subject.execute
      end
    end

    context 'when downloaded lfs file has a different oid' do
      before do
        stub_full_request(download_link).to_return(body: lfs_content)
        allow_any_instance_of(Digest::SHA256).to receive(:hexdigest).and_return('foobar')
      end

      it_behaves_like 'no lfs object is created'

      it 'raise OidError exception' do
        expect(subject).to receive(:download_and_save_file!).and_raise(described_class::OidError)

        subject.execute
      end
    end

    context 'when an lfs object with the same oid already exists' do
      let!(:existing_lfs_object) { create(:lfs_object, oid: oid) }

      before do
        stub_full_request(download_link).to_return(body: lfs_content)
      end

      it_behaves_like 'no lfs object is created'

      it 'does not update the file attached to the existing LfsObject' do
        expect { subject.execute }
          .not_to change { existing_lfs_object.reload.file.file.file }
      end
    end

    context 'when credentials present' do
      let(:download_link_with_credentials) { "http://user:password@gitlab.com/#{oid}" }
      let(:lfs_object) { LfsDownloadObject.new(oid: oid, size: size, link: download_link_with_credentials) }

      before do
        stub_full_request(download_link).with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNzd29yZA==' }).to_return(body: lfs_content)
      end

      it 'the request adds authorization headers' do
        subject
      end
    end

    context 'when localhost requests are allowed' do
      let(:download_link) { 'http://192.168.2.120' }
      let(:local_request_setting) { true }

      before do
        stub_full_request(download_link, ip_address: '192.168.2.120').to_return(body: lfs_content)
      end

      it_behaves_like 'lfs object is created'
    end

    context 'when a bad URL is used' do
      where(download_link: ['/etc/passwd', 'ftp://example.com', 'http://127.0.0.2', 'http://192.168.2.120'])

      with_them do
        it 'does not download the file' do
          expect(subject).not_to receive(:download_lfs_file!)

          expect { subject.execute }.not_to change { LfsObject.count }
        end
      end
    end

    context 'when the URL points to a redirected URL' do
      context 'that is blocked' do
        where(redirect_link: ['ftp://example.com', 'http://127.0.0.2', 'http://192.168.2.120'])

        with_them do
          before do
            stub_full_request(download_link, ip_address: '192.168.2.120')
              .to_return(status: 301, headers: { 'Location' => redirect_link })
          end

          it_behaves_like 'no lfs object is created'
        end
      end

      context 'that is not blocked' do
        let(:redirect_link) { "http://example.com/"}

        before do
          stub_full_request(download_link).to_return(status: 301, headers: { 'Location' => redirect_link })
          stub_full_request(redirect_link).to_return(body: lfs_content)
        end

        it_behaves_like 'lfs object is created'
      end
    end

    context 'when the lfs object attributes are invalid' do
      let(:oid) { 'foobar' }

      before do
        expect(lfs_object).to be_invalid
      end

      it_behaves_like 'no lfs object is created'

      it 'does not download the file' do
        expect(subject).not_to receive(:download_lfs_file!)

        subject.execute
      end
    end

    context 'when a large lfs object with the same oid already exists' do
      let!(:existing_lfs_object) { create(:lfs_object, :with_file, :correct_oid) }

      before do
        stub_const("#{described_class}::LARGE_FILE_SIZE", 500)
        stub_full_request(download_link).to_return(body: lfs_content)
      end

      context 'and first fragments are the same' do
        let(:lfs_content) { existing_lfs_object.file.read }

        context 'when lfs_link_existing_object feature flag disabled' do
          before do
            stub_feature_flags(lfs_link_existing_object: false)
          end

          it 'does not call link_existing_lfs_object!' do
            expect(subject).not_to receive(:link_existing_lfs_object!)

            subject.execute
          end
        end

        it 'returns success' do
          expect(subject.execute).to eq({ status: :success })
        end

        it 'links existing lfs object to the project' do
          expect { subject.execute }
            .to change { project.lfs_objects.include?(existing_lfs_object) }.from(false).to(true)
        end
      end

      context 'and first fragments diverges' do
        let(:lfs_content) { SecureRandom.random_bytes(1000) }
        let(:oid) { existing_lfs_object.oid }

        it 'raises oid mismatch error' do
          expect(subject.execute).to eq({
            status: :error,
            message: "LFS file with oid #{oid} cannot be linked with an existing LFS object"
          })
        end

        it 'does not change lfs objects' do
          expect { subject.execute }.not_to change { project.lfs_objects }
        end
      end
    end
  end
end
