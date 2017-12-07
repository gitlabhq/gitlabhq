require 'spec_helper'

describe HasVariable do
  subject { build(:ci_variable) }

  it { is_expected.to validate_presence_of(:key) }
  it { is_expected.to validate_length_of(:key).is_at_most(255) }
  it { is_expected.to allow_value('foo').for(:key) }
  it { is_expected.not_to allow_value('foo bar').for(:key) }
  it { is_expected.not_to allow_value('foo/bar').for(:key) }

  describe '#key=' do
    context 'when the new key is nil' do
      it 'strips leading and trailing whitespaces' do
        subject.key = nil

        expect(subject.key).to eq('')
      end
    end

    context 'when the new key has leadind and trailing whitespaces' do
      it 'strips leading and trailing whitespaces' do
        subject.key = ' my key '

        expect(subject.key).to eq('my key')
      end
    end
  end

  describe '#value' do
    before do
      subject.value = 'secret'
    end

    it 'stores the encrypted value' do
      expect(subject.encrypted_value).not_to be_nil
    end

    it 'stores an iv for value' do
      expect(subject.encrypted_value_iv).not_to be_nil
    end

    it 'stores a salt for value' do
      expect(subject.encrypted_value_salt).not_to be_nil
    end

    it 'fails to decrypt if iv is incorrect' do
      subject.encrypted_value_iv = SecureRandom.hex
      subject.instance_variable_set(:@value, nil)
      expect { subject.value }
        .to raise_error(OpenSSL::Cipher::CipherError, 'bad decrypt')
    end
  end

  describe '#to_runner_variable' do
    it 'returns a hash for the runner' do
      expect(subject.to_runner_variable)
        .to eq(key: subject.key, value: subject.value, public: false)
    end
  end
end
