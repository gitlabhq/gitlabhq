require 'spec_helper'

describe Gitlab::BackgroundMigration::NormalizeLdapExternUidsRange, :migration, schema: 20170921101004 do
  let!(:identities) { table(:identities) }

  before do
    # LDAP identities
    (1..4).each do |i|
      identities.create!(id: i, provider: 'ldapmain', extern_uid: " uid = foo #{i}, ou = People, dc = example, dc = com ", user_id: i)
    end

    # Non-LDAP identity
    identities.create!(id: 5, provider: 'foo', extern_uid: " uid = foo 5, ou = People, dc = example, dc = com ", user_id: 5)

    # Another LDAP identity
    identities.create!(id: 6, provider: 'ldapmain', extern_uid: " uid = foo 6, ou = People, dc = example, dc = com ", user_id: 6)
  end

  it 'normalizes the LDAP identities in the range' do
    described_class.new.perform(1, 3)
    expect(identities.find(1).extern_uid).to eq("uid=foo 1,ou=people,dc=example,dc=com")
    expect(identities.find(2).extern_uid).to eq("uid=foo 2,ou=people,dc=example,dc=com")
    expect(identities.find(3).extern_uid).to eq("uid=foo 3,ou=people,dc=example,dc=com")
    expect(identities.find(4).extern_uid).to eq(" uid = foo 4, ou = People, dc = example, dc = com ")
    expect(identities.find(5).extern_uid).to eq(" uid = foo 5, ou = People, dc = example, dc = com ")
    expect(identities.find(6).extern_uid).to eq(" uid = foo 6, ou = People, dc = example, dc = com ")

    described_class.new.perform(4, 6)
    expect(identities.find(1).extern_uid).to eq("uid=foo 1,ou=people,dc=example,dc=com")
    expect(identities.find(2).extern_uid).to eq("uid=foo 2,ou=people,dc=example,dc=com")
    expect(identities.find(3).extern_uid).to eq("uid=foo 3,ou=people,dc=example,dc=com")
    expect(identities.find(4).extern_uid).to eq("uid=foo 4,ou=people,dc=example,dc=com")
    expect(identities.find(5).extern_uid).to eq(" uid = foo 5, ou = People, dc = example, dc = com ")
    expect(identities.find(6).extern_uid).to eq("uid=foo 6,ou=people,dc=example,dc=com")
  end
end
