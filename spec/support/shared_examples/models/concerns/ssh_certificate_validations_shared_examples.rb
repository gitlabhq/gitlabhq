# frozen_string_literal: true

# Requires a context with:
# - subject
#
RSpec.shared_examples 'an SSH certificate record' do |factory_name:|
  describe 'validations' do
    it 'presence fields' do
      is_expected.to validate_presence_of(:key)
      is_expected.to validate_presence_of(:title)
      is_expected.to validate_presence_of(:fingerprint)
    end

    it 'length of key and title' do
      is_expected.to validate_length_of(:title).is_at_most(255)
      is_expected.to validate_length_of(:key).is_at_most(5000)
    end

    it 'format of the key' do
      is_expected.to allow_value(build(:rsa_key_4096).key).for(:key)
      is_expected.not_to allow_value('unsupported-ssh-rsa key').for(:key)
    end

    it_behaves_like 'meets ssh key restrictions'
  end

  describe '.for_fingerprint' do
    # rubocop:disable Rails/SaveBang -- These are FactoryBot calls, not ActiveRecord ones
    let_it_be(:certificate) { create(factory_name) }
    let_it_be(:other_certificate) { create(factory_name) }
    # rubocop:enable Rails/SaveBang

    it 'returns only the certificate matching the fingerprint' do
      expect(described_class.for_fingerprint(certificate.fingerprint)).to contain_exactly(certificate)
    end

    it 'returns empty when no certificate matches' do
      expect(described_class.for_fingerprint('nonexistent')).to be_empty
    end
  end
end
