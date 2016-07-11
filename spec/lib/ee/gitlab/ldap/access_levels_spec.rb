require 'spec_helper'

describe EE::Gitlab::LDAP::AccessLevels, lib: true do
  describe '#set' do
    let(:access_levels) { described_class.new }
    let(:dns) do
      %w(
      uid=johndoe,ou=users,dc=example,dc=com
      uid=janedoe,ou=users,dc=example,dc=com
    )
    end
    subject { access_levels }

    context 'when access_levels is empty' do
      before { access_levels.set(dns, to: Gitlab::Access::DEVELOPER) }

      it do
        is_expected
          .to eq({
            'uid=janedoe,ou=users,dc=example,dc=com' => Gitlab::Access::DEVELOPER,
            'uid=johndoe,ou=users,dc=example,dc=com' => Gitlab::Access::DEVELOPER
          })
      end
    end

    context 'when access_hash has existing entries' do
      let(:developer_dns) do
        %w{
          uid=janedoe,ou=users,dc=example,dc=com
          uid=jamesdoe,ou=users,dc=example,dc=com
        }
      end
      let(:master_dns) do
        %w{
          uid=johndoe,ou=users,dc=example,dc=com
          uid=janedoe,ou=users,dc=example,dc=com
        }
      end
      before do
        access_levels.set(master_dns, to: Gitlab::Access::MASTER)
        access_levels.set(developer_dns, to: Gitlab::Access::DEVELOPER)
      end

      it 'keeps the higher of all access values' do
        is_expected
          .to eq({
             'uid=janedoe,ou=users,dc=example,dc=com'  => Gitlab::Access::MASTER,
             'uid=johndoe,ou=users,dc=example,dc=com'  => Gitlab::Access::MASTER,
             'uid=jamesdoe,ou=users,dc=example,dc=com' => Gitlab::Access::DEVELOPER
          })
      end
    end
  end
end
