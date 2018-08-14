require 'spec_helper'

describe Gitlab::PagesClient do
  subject { described_class }

  describe '.token' do
    it 'returns the token as it is on disk' do
      pending 'add omnibus support for generating the secret file https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2466'
      expect(subject.token).to eq(File.read('.gitlab_pages_secret'))
    end
  end

  describe '.read_or_create_token' do
    subject { described_class.read_or_create_token }
    let(:token_path) { 'tmp/tests/gitlab-pages-secret' }
    before do
      allow(described_class).to receive(:token_path).and_return(token_path)
      FileUtils.rm_f(token_path)
    end

    it 'uses the existing token file if it exists' do
      secret = 'existing secret'
      File.write(token_path, secret)

      subject
      expect(described_class.token).to eq(secret)
    end

    it 'creates one if none exists' do
      pending 'add omnibus support for generating the secret file https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2466'

      old_token = described_class.token
      # sanity check
      expect(File.exist?(token_path)).to eq(false)

      subject
      expect(described_class.token.bytesize).to eq(64)
      expect(described_class.token).not_to eq(old_token)
    end
  end

  describe '.write_token' do
    let(:token_path) { 'tmp/tests/gitlab-pages-secret' }
    before do
      allow(described_class).to receive(:token_path).and_return(token_path)
      FileUtils.rm_f(token_path)
    end

    it 'writes the secret' do
      new_secret = 'hello new secret'
      expect(File.exist?(token_path)).to eq(false)

      described_class.send(:write_token, new_secret)

      expect(File.read(token_path)).to eq(new_secret)
    end

    it 'does nothing if the file already exists' do
      existing_secret = 'hello secret'
      File.write(token_path, existing_secret)

      described_class.send(:write_token, 'new secret')

      expect(File.read(token_path)).to eq(existing_secret)
    end
  end

  describe '.load_certificate' do
    subject { described_class.load_certificate }
    before do
      allow(described_class).to receive(:config).and_return(config)
    end

    context 'with no certificate in the config' do
      let(:config) { double(:config, certificate: '') }

      it 'does not set @certificate' do
        subject

        expect(described_class.certificate).to be_nil
      end
    end

    context 'with a certificate path in the config' do
      let(:certificate_path) { 'tmp/tests/fake-certificate' }
      let(:config) { double(:config, certificate: certificate_path) }

      it 'sets @certificate' do
        certificate_data = "--- BEGIN CERTIFICATE ---\nbla\n--- END CERTIFICATE ---\n"
        File.write(certificate_path, certificate_data)
        subject

        expect(described_class.certificate).to eq(certificate_data)
      end
    end
  end

  describe '.request_kwargs' do
    let(:token) { 'secret token' }
    let(:auth_header) { 'Bearer c2VjcmV0IHRva2Vu' }
    before do
      allow(described_class).to receive(:token).and_return(token)
    end

    context 'without timeout' do
      it { expect(subject.send(:request_kwargs, nil)[:metadata]['authorization']).to eq(auth_header) }
    end

    context 'with timeout' do
      let(:timeout) { 1.second }

      it 'still sets the authorization header' do
        expect(subject.send(:request_kwargs, timeout)[:metadata]['authorization']).to eq(auth_header)
      end

      it 'sets a deadline value' do
        now = Time.now
        deadline = subject.send(:request_kwargs, timeout)[:deadline]

        expect(deadline).to be_between(now, now + 2 * timeout)
      end
    end
  end

  describe '.stub' do
    before do
      allow(described_class).to receive(:address).and_return('unix:/foo/bar')
    end

    it { expect(subject.send(:stub, :health_check)).to be_a(Grpc::Health::V1::Health::Stub) }
  end

  describe '.address' do
    subject { described_class.send(:address) }

    before do
      allow(described_class).to receive(:config).and_return(config)
    end

    context 'with a unix: address' do
      let(:config) { double(:config, address: 'unix:/foo/bar') }

      it { expect(subject).to eq('unix:/foo/bar') }
    end

    context 'with a tcp:// address' do
      let(:config) { double(:config, address: 'tcp://localhost:1234') }

      it { expect(subject).to eq('localhost:1234') }
    end
  end

  describe '.grpc_creds' do
    subject { described_class.send(:grpc_creds) }

    before do
      allow(described_class).to receive(:config).and_return(config)
    end

    context 'with a unix: address' do
      let(:config) { double(:config, address: 'unix:/foo/bar') }

      it { expect(subject).to eq(:this_channel_is_insecure) }
    end

    context 'with a tcp:// address' do
      let(:config) { double(:config, address: 'tcp://localhost:1234') }

      it { expect(subject).to be_a(GRPC::Core::ChannelCredentials) }
    end
  end
end
