# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Ldap::Person do
  include LdapHelpers

  let(:entry) { ldap_user_entry('john.doe') }

  before do
    stub_ldap_config(
      options: {
        'uid' => 'uid',
        'attributes' => {
          'name' => 'cn',
          'email' => %w[mail email userPrincipalName],
          'username' => username_attribute
        }
      }
    )
  end

  let(:username_attribute) { %w[uid sAMAccountName userid] }

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

  describe '.ldap_attributes' do
    it 'returns a compact and unique array' do
      stub_ldap_config(
        options: {
          'uid' => nil,
          'attributes' => {
            'name' => 'cn',
            'email' => 'mail',
            'username' => %w[uid mail],
            'first_name' => ''
          }
        }
      )
      config = Gitlab::Auth::Ldap::Config.new('ldapmain')
      ldap_attributes = described_class.ldap_attributes(config)

      expect(ldap_attributes).to include('dn', 'uid', 'cn', 'mail')
      expect(ldap_attributes).to be_present
      expect(ldap_attributes.uniq!).to eq(nil)
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

  describe '#username' do
    context 'with default uid username attribute' do
      let(:username_attribute) { 'uid' }

      it 'returns the proper username value' do
        attr_value = 'johndoe'
        entry[username_attribute] = attr_value
        person = described_class.new(entry, 'ldapmain')

        expect(person.username).to eq(attr_value)
      end
    end

    context 'with a different username attribute' do
      let(:username_attribute) { 'sAMAccountName' }

      it 'returns the proper username value' do
        attr_value = 'johndoe'
        entry[username_attribute] = attr_value
        person = described_class.new(entry, 'ldapmain')

        expect(person.username).to eq(attr_value)
      end
    end

    context 'with a non-standard username attribute' do
      let(:username_attribute) { 'mail' }

      it 'returns the proper username value' do
        attr_value = 'john.doe@example.com'
        entry[username_attribute] = attr_value
        person = described_class.new(entry, 'ldapmain')

        expect(person.username).to eq(attr_value)
      end
    end

    context 'if lowercase_usernames setting is' do
      let(:username_attribute) { 'uid' }

      before do
        entry[username_attribute] = +'JOHN'
        @person = described_class.new(entry, 'ldapmain')
      end

      it 'enabled the username attribute is lower cased' do
        stub_ldap_config(lowercase_usernames: true)

        expect(@person.username).to eq 'john'
      end

      it 'disabled the username attribute is not lower cased' do
        stub_ldap_config(lowercase_usernames: false)

        expect(@person.username).to eq 'JOHN'
      end
    end
  end

  def assert_generic_test(test_description, got, expected)
    test_failure_message = "Failed test description: '#{test_description}'\n\n    expected: #{expected}\n         got: #{got}"
    expect(got).to eq(expected), test_failure_message
  end
end
