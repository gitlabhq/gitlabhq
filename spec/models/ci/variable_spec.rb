require 'spec_helper'

describe Ci::Variable, models: true do
  subject { build(:ci_variable) }

  let(:secret_value) { 'secret' }

  it { is_expected.to validate_presence_of(:key) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:key).is_at_most(255) }
  it { is_expected.to allow_value('foo').for(:key) }
  it { is_expected.not_to allow_value('foo bar').for(:key) }
  it { is_expected.not_to allow_value('foo/bar').for(:key) }

  describe '.unprotected' do
    subject { described_class.unprotected }

    context 'when variable is protected' do
      before do
        create(:ci_variable, :protected)
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when variable is not protected' do
      let(:variable) { create(:ci_variable, protected: false) }

      it 'returns the variable' do
        is_expected.to contain_exactly(variable)
      end
    end
  end

  describe '#value' do
    before do
      subject.value = secret_value
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
