require 'spec_helper'

describe Gitlab::LDAP::Person do
  include LdapHelpers

  let(:entry) { ldap_user_entry('john.doe') }

  before do
    stub_ldap_config(
      attributes: {
        name: 'cn',
        email: %w(mail email userPrincipalName)
      }
    )
  end

  describe '#name' do
    it 'uses the configured name attribute and handles values as an array' do
      name = 'John Doe'
      entry['cn'] = [name]
      person = Gitlab::LDAP::Person.new(entry, 'ldapmain')

      expect(person.name).to eq(name)
    end
  end

  describe '#email' do
    it 'returns the value of mail, if present' do
      mail = 'john@example.com'
      entry['mail'] = mail
      person = Gitlab::LDAP::Person.new(entry, 'ldapmain')

      expect(person.email).to eq(mail)
    end

    it 'returns the value of userPrincipalName, if mail and email are not present' do
      user_principal_name = 'john.doe@example.com'
      entry['userPrincipalName'] = user_principal_name
      person = Gitlab::LDAP::Person.new(entry, 'ldapmain')

      expect(person.email).to eq(user_principal_name)
    end
  end
end
