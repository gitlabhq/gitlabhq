require 'spec_helper'

describe EE::Gitlab::LDAP::Sync::AdminUsers, lib: true do
  include LdapHelpers

  describe '#update_permissions' do
    let(:sync_admin) { described_class.new(proxy(adapter)) }

    let(:user) { create(:user) }

    let(:admin_group) do
      ldap_group_entry(user_dn(user.username), cn: 'admin_group')
    end

    before do
      stub_ldap_config(admin_group: 'admin_group', active_directory: false)
      stub_ldap_group_find_by_cn('admin_group', admin_group, adapter)
    end

    it 'adds user as admin' do
      create(:identity, user: user, extern_uid: user_dn(user.username))

      expect { sync_admin.update_permissions }
        .to change { user.reload.admin? }.from(false).to(true)
    end

    it 'removes users that are not in the LDAP group' do
      admin = create(:admin)
      create(:identity, user: admin, extern_uid: user_dn(admin.username))

      expect { sync_admin.update_permissions }
        .to change { admin.reload.admin? }.from(true).to(false)
    end

    it 'leaves admin users that do not have the LDAP provider' do
      admin = create(:admin)

      expect { sync_admin.update_permissions }
        .not_to change { admin.reload.admin? }
    end

    it 'leaves admin users that have a different provider identity' do
      admin = create(:admin)
      create(:identity,
             user: admin,
             provider: 'ldapsecondary',
             extern_uid: user_dn(admin.username))

      expect { sync_admin.update_permissions }
        .not_to change { admin.reload.admin? }
    end
  end
end
