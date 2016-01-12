# == Schema Information
#
# Table name: identities
#
#  id         :integer          not null, primary key
#  extern_uid :string(255)
#  provider   :string(255)
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

RSpec.describe Identity, models: true do

  describe 'relations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'fields' do
    it { is_expected.to respond_to(:provider) }
    it { is_expected.to respond_to(:extern_uid) }
  end

  describe '#is_ldap?' do
    let(:ldap_identity) { create(:identity, provider: 'ldapmain') }
    let(:other_identity) { create(:identity, provider: 'twitter') }

    it 'returns true if it is a ldap identity' do
      expect(ldap_identity.ldap?).to be_truthy
    end

    it 'returns false if it is not a ldap identity' do
      expect(other_identity.ldap?).to be_falsey
    end
  end
end
