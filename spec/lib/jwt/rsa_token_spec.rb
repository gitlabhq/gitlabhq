describe Jwt::RSAToken do
  let(:rsa_key) { generate_key }
  let(:rsa_token) { described_class.new(nil) }
  let(:rsa_encoded) { rsa_token.encoded }

  before { allow_any_instance_of(described_class).to receive(:key).and_return(rsa_key) }

  context 'token' do
    context 'for valid key to be validated' do
      before { rsa_token['key'] = 'value' }

      subject { JWT.decode(rsa_encoded, rsa_key) }

      it { expect{subject}.to_not raise_error }
      it { expect(subject.first).to include('key' => 'value') }
    end

    context 'for invalid key to raise an exception' do
      let(:new_key) { generate_key }
      subject { JWT.decode(rsa_encoded, new_key) }

      it { expect{subject}.to raise_error(JWT::DecodeError) }
    end
  end

  private

  def generate_key
    OpenSSL::PKey::RSA.generate(512)
  end
end
