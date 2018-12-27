require 'spec_helper'

describe Projects::LfsPointers::LfsDownloadService do
  let(:project) { create(:project) }
  let(:oid) { '9e548e25631dd9ce6b43afd6359ab76da2819d6a5b474e66118c7819e1d8b3e8' }
  let(:download_link) { "http://gitlab.com/#{oid}" }
  let(:lfs_content) { SecureRandom.random_bytes(10) }

  subject { described_class.new(project) }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(true)
    WebMock.stub_request(:get, download_link).to_return(body: lfs_content)

    allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_hooks_and_services?).and_return(false)
  end

  describe '#execute' do
    context 'when file download succeeds' do
      it 'a new lfs object is created' do
        expect { subject.execute(oid, download_link) }.to change { LfsObject.count }.from(0).to(1)
      end

      it 'has the same oid' do
        subject.execute(oid, download_link)

        expect(LfsObject.first.oid).to eq oid
      end

      it 'stores the content' do
        subject.execute(oid, download_link)

        expect(File.binread(LfsObject.first.file.file.file)).to eq lfs_content
      end
    end

    context 'when file download fails' do
      it 'no lfs object is created' do
        expect { subject.execute(oid, download_link) }.to change { LfsObject.count }
      end
    end

    context 'when credentials present' do
      let(:download_link_with_credentials) { "http://user:password@gitlab.com/#{oid}" }

      before do
        WebMock.stub_request(:get, download_link).with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNzd29yZA==' }).to_return(body: lfs_content)
      end

      it 'the request adds authorization headers' do
        subject.execute(oid, download_link_with_credentials)
      end
    end

    context 'when localhost requests are allowed' do
      let(:download_link) { 'http://192.168.2.120' }

      before do
        allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_hooks_and_services?).and_return(true)
      end

      it 'downloads the file' do
        expect(subject).to receive(:download_and_save_file).and_call_original

        expect { subject.execute(oid, download_link) }.to change { LfsObject.count }.by(1)
      end
    end

    context 'when a bad URL is used' do
      where(download_link: ['/etc/passwd', 'ftp://example.com', 'http://127.0.0.2', 'http://192.168.2.120'])

      with_them do
        it 'does not download the file' do
          expect { subject.execute(oid, download_link) }.not_to change { LfsObject.count }
        end
      end
    end

    context 'when the URL points to a redirected URL' do
      context 'that is blocked' do
        where(redirect_link: ['ftp://example.com', 'http://127.0.0.2', 'http://192.168.2.120'])

        with_them do
          before do
            WebMock.stub_request(:get, download_link).to_return(status: 301, headers: { 'Location' => redirect_link })
          end

          it 'does not follow the redirection' do
            expect(Rails.logger).to receive(:error).with(/LFS file with oid #{oid} couldn't be downloaded/)

            expect { subject.execute(oid, download_link) }.not_to change { LfsObject.count }
          end
        end
      end

      context 'that is valid' do
        let(:redirect_link) { "http://example.com/"}

        before do
          WebMock.stub_request(:get, download_link).to_return(status: 301, headers: { 'Location' => redirect_link })
          WebMock.stub_request(:get, redirect_link).to_return(body: lfs_content)
        end

        it 'follows the redirection' do
          expect { subject.execute(oid, download_link) }.to change { LfsObject.count }.from(0).to(1)
        end
      end
    end

    context 'when an lfs object with the same oid already exists'  do
      before do
        create(:lfs_object, oid: 'oid')
      end

      it 'does not download the file' do
        expect(subject).not_to receive(:download_and_save_file)

        subject.execute('oid', download_link)
      end
    end
  end
end
