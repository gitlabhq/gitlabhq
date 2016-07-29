require 'spec_helper'

describe LdapGroupLink do
  let(:klass) { LdapGroupLink }
  let(:ldap_group_link) { build :ldap_group_link }

  describe "validation" do
    describe "cn" do
      it "validates uniquiness based on group_id and provider" do
        create(:ldap_group_link, cn: 'group1', group_id: 1, provider: 'ldapmain')

        group_link = build(:ldap_group_link,
          cn: 'group1', group_id: 1, provider: 'ldapmain')
        expect(group_link).not_to be_valid

        group_link.group_id = 2
        expect(group_link).to be_valid

        group_link.group_id = 1
        group_link.provider = 'ldapalt'
        expect(group_link).to be_valid
      end
    end

    describe :provider do
      it "shows the set value" do
        ldap_group_link.provider = '1235'
        expect( ldap_group_link.provider ).to eql '1235'
      end

      it "defaults to the first ldap server if empty" do
        expect( klass.new.provider ).to eql Gitlab::LDAP::Config.providers.first
      end
    end
  end
end
