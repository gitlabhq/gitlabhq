require 'spec_helper'

describe Gitlab::LDAP::Person do
  include LdapHelpers

  let(:entry) { ldap_user_entry('john.doe') }

  before do
    stub_ldap_config(
      options: {
        'attributes' => {
          'name' => 'cn',
          'email' => %w(mail email userPrincipalName)
        }
      }
    )
  end

  describe '.normalize_dn' do
    subject { described_class.normalize_dn(given) }

    it_behaves_like 'normalizes a DN'

    context 'with an exception during normalization' do
      let(:given) { 'John "Smith,' } # just something that will cause an exception

      it 'returns the given DN unmodified' do
        expect(subject).to eq(given)
      end
    end
  end

  describe '.normalize_uid' do
    subject { described_class.normalize_uid(given) }

    it_behaves_like 'normalizes a DN attribute value'

    context 'with an exception during normalization' do
      let(:given) { 'John "Smith,' } # just something that will cause an exception

      it 'returns the given UID unmodified' do
        expect(subject).to eq(given)
      end
    end
  end

  describe '#name' do
    it 'uses the configured name attribute and handles values as an array' do
      name = 'John Doe'
      entry['cn'] = [name]
      person = described_class.new(entry, 'ldapmain')

      expect(person.name).to eq(name)
    end
  end

  describe '#email' do
    it 'returns the value of mail, if present' do
      mail = 'john@example.com'
      entry['mail'] = mail
      person = described_class.new(entry, 'ldapmain')

      expect(person.email).to eq([mail])
    end

    it 'returns the value of userPrincipalName, if mail and email are not present' do
      user_principal_name = 'john.doe@example.com'
      entry['userPrincipalName'] = user_principal_name
      person = described_class.new(entry, 'ldapmain')

      expect(person.email).to eq([user_principal_name])
    end
  end

  def assert_generic_test(test_description, got, expected)
    test_failure_message = "Failed test description: '#{test_description}'\n\n    expected: #{expected}\n         got: #{got}"
    expect(got).to eq(expected), test_failure_message
  end
end
