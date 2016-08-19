require 'spec_helper'

describe Gitlab::Workhorse, lib: true do
  let(:project) { create(:project) }
  let(:subject) { Gitlab::Workhorse }

  describe ".send_git_archive" do
    context "when the repository doesn't have an archive file path" do
      before do
        allow(project.repository).to receive(:archive_metadata).and_return(Hash.new)
      end

      it "raises an error" do
        expect { subject.send_git_archive(project.repository, ref: "master", format: "zip") }.to raise_error(RuntimeError)
      end
    end
  end

  describe ".secret" do
    subject { described_class.secret }

    before do
      described_class.instance_variable_set(:@secret, nil)
      described_class.write_secret
    end

    it 'returns 32 bytes' do
      expect(subject).to be_a(String)
      expect(subject.length).to eq(32)
      expect(subject.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it 'raises an exception if the secret file cannot be read' do
      File.delete(described_class.secret_path)
      expect { subject }.to raise_exception(Errno::ENOENT)
    end

    it 'raises an exception if the secret file contains the wrong number of bytes' do
      File.truncate(described_class.secret_path, 0)
      expect { subject }.to raise_exception(RuntimeError)
    end
  end

  describe ".write_secret" do
    let(:secret_path) { described_class.secret_path }
    before do
      begin
        File.delete(secret_path)
      rescue Errno::ENOENT
      end

      described_class.write_secret
    end

    it 'uses mode 0600' do
      expect(File.stat(secret_path).mode & 0777).to eq(0600)
    end

    it 'writes base64 data' do
      bytes = Base64.strict_decode64(File.read(secret_path))
      expect(bytes).not_to be_empty
    end
  end

  describe '#verify_api_request!' do
    let(:header_key) { described_class.const_get('INTERNAL_API_REQUEST_HEADER') }
    let(:payload) { { 'iss' => 'gitlab-workhorse' } }

    it 'accepts a correct header' do
      headers = { header_key => JWT.encode(payload, described_class.secret, 'HS256') }
      expect { call_verify(headers) }.not_to raise_error
    end

    it 'raises an error when the header is not set' do
      expect { call_verify({}) }.to raise_jwt_error
    end

    it 'raises an error when the header is not signed' do
      headers = { header_key => JWT.encode(payload, nil, 'none') }
      expect { call_verify(headers) }.to raise_jwt_error
    end

    it 'raises an error when the header is signed with the wrong key' do
      headers = { header_key => JWT.encode(payload, 'wrongkey', 'HS256') }
      expect { call_verify(headers) }.to raise_jwt_error
    end

    it 'raises an error when the issuer is incorrect' do
      payload['iss'] = 'somebody else'
      headers = { header_key => JWT.encode(payload, described_class.secret, 'HS256') }
      expect { call_verify(headers) }.to raise_jwt_error
    end

    def raise_jwt_error
      raise_error(JWT::DecodeError)
    end

    def call_verify(headers)
      described_class.verify_api_request!(headers)
    end
  end
end
