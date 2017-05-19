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

  describe '#memberof' do
    it 'returns an empty array if the field was not present' do
      person = described_class.new(entry, 'ldapmain')

      expect(person.memberof).to eq([])
    end

    it 'returns the values of `memberof` if the field was present' do
      example_memberof = ['CN=Group Policy Creator Owners,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Domain Admins,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Enterprise Admins,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Schema Admins,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Administrators,CN=Builtin,DC=Vosmaer,DC=com']
      entry['memberof'] = example_memberof
      person = described_class.new(entry, 'ldapmain')

      expect(person.memberof).to eq(example_memberof)
    end
  end

  describe '#cn_from_memberof' do
    it 'gets the group cn from the memberof value' do
      person = described_class.new(entry, 'ldapmain')

      expect(person.cn_from_memberof('cN=Group Policy Creator Owners,CN=Users,DC=Vosmaer,DC=com'))
        .to eq('Group Policy Creator Owners')
    end

    it "doesn't break when there is no CN property" do
      person = described_class.new(entry, 'ldapmain')

      expect(person.cn_from_memberof('DC=Vosmaer,DC=com'))
        .to be_nil
    end
  end

  describe '#group_cns' do
    it 'returns only CNs from the memberof values' do
      example_memberof = ['CN=Group Policy Creator Owners,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Administrators,CN=Builtin,DC=Vosmaer,DC=com']
      entry['memberof'] = example_memberof
      person = described_class.new(entry, 'ldapmain')

      expect(person.group_cns).to eq(['Group Policy Creator Owners', 'Administrators'])
    end
  end
end
