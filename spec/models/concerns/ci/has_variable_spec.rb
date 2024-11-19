# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::HasVariable, feature_category: :continuous_integration do
  subject { build(:ci_variable) }

  it { is_expected.to validate_presence_of(:key) }
  it { is_expected.to validate_length_of(:key).is_at_most(255) }
  it { is_expected.to allow_value('foo').for(:key) }
  it { is_expected.not_to allow_value('foo bar').for(:key) }
  it { is_expected.not_to allow_value('foo/bar').for(:key) }

  describe 'scopes' do
    describe '.by_key' do
      let!(:matching_variable) { create(:ci_variable, key: 'example') }
      let!(:non_matching_variable) { create(:ci_variable, key: 'other') }

      subject { Ci::Variable.by_key('example') }

      it { is_expected.to contain_exactly(matching_variable) }
    end
  end

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
      # attr_encrypted expects the IV to be 16 bytes and base64-encoded
      subject.encrypted_value_iv = [SecureRandom.hex(8)].pack('m')
      subject.instance_variable_set(:@value, nil)

      expect { subject.value }
        .to raise_error(OpenSSL::Cipher::CipherError, 'bad decrypt')
    end
  end

  describe '#to_hash_variable' do
    let_it_be(:ci_variable) { create(:ci_variable) }

    subject { ci_variable }

    it 'returns a hash for the runner' do
      expect(subject.to_hash_variable)
        .to include(key: subject.key, value: subject.value, public: false)
    end

    context 'with RequestStore enabled', :request_store do
      let(:expected) do
        {
          file: false,
          key: subject.key,
          value: subject.value,
          public: false,
          raw: false,
          masked: false
        }
      end

      it 'decrypts once' do
        expect(OpenSSL::PKCS5).to receive(:pbkdf2_hmac).once.and_call_original

        2.times { expect(subject.reload.to_hash_variable).to eq(expected) }
      end

      it 'does not cache similar keys', :aggregate_failures do
        group_var = create(:ci_group_variable, key: subject.key, value: 'group')
        project_var = create(:ci_variable, key: subject.key, value: 'project')

        expect(subject.to_hash_variable).to include(key: subject.key, value: subject.value)
        expect(group_var.to_hash_variable).to include(key: subject.key, value: 'group')
        expect(project_var.to_hash_variable).to include(key: subject.key, value: 'project')
      end

      it 'does not cache unpersisted values' do
        new_variable = Ci::Variable.new(key: SecureRandom.hex, value: "12345")
        old_value = new_variable.to_hash_variable
        new_variable.value = '98765'

        expect(new_variable.to_hash_variable).not_to eq(old_value)
      end
    end
  end

  describe '.order_by' do
    let_it_be(:relation) { Ci::Variable.all }

    it 'supports ordering by key ascending' do
      expect(relation).to receive(:reorder).with({ key: :asc })

      relation.order_by('key_asc')
    end

    it 'supports ordering by key descending' do
      expect(relation).to receive(:reorder).with({ key: :desc })

      relation.order_by('key_desc')
    end

    context 'when order method is unknown' do
      it 'does not call reorder' do
        expect(relation).not_to receive(:reorder)

        relation.order_by('unknown')
      end
    end

    context 'when order method is nil' do
      it 'does not call reorder' do
        expect(relation).not_to receive(:reorder)

        relation.order_by(nil)
      end
    end
  end
end
