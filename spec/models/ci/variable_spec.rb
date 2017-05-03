require 'spec_helper'

describe Ci::Variable, models: true do
  subject { Ci::Variable.new }

  let(:secret_value) { 'secret' }

  it { is_expected.to validate_presence_of(:key) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:gl_project_id) }
  it { is_expected.to validate_length_of(:key).is_at_most(255) }
  it { is_expected.to allow_value('foo').for(:key) }
  it { is_expected.not_to allow_value('foo bar').for(:key) }
  it { is_expected.not_to allow_value('foo/bar').for(:key) }

  before :each do
    subject.value = secret_value
  end

  describe '#value' do
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
      expect { subject.value }.
        to raise_error(OpenSSL::Cipher::CipherError, 'bad decrypt')
    end
  end
end
