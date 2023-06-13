# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Identity do
  describe 'relations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'fields' do
    it { is_expected.to respond_to(:provider) }
    it { is_expected.to respond_to(:extern_uid) }
  end

  describe 'validations' do
    let_it_be(:user) { create(:user) }

    context 'with existing user and provider' do
      before do
        create(:identity, provider: 'ldapmain', user_id: user.id)
      end

      it 'returns false for a duplicate entry' do
        identity = user.identities.build(provider: 'ldapmain', user_id: user.id)

        expect(identity.validate).to be_falsey
      end

      it 'returns true when a different provider is used' do
        identity = user.identities.build(provider: 'gitlab', user_id: user.id)

        expect(identity.validate).to be_truthy
      end
    end

    context 'with newly-created user' do
      before do
        create(:identity, provider: 'ldapmain', user_id: nil)
      end

      it 'successfully validates even with a nil user_id' do
        identity = user.identities.build(provider: 'ldapmain')

        expect(identity.validate).to be_truthy
      end
    end
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

  describe '.with_extern_uid' do
    context 'LDAP identity' do
      let!(:ldap_identity) { create(:identity, provider: 'ldapmain', extern_uid: 'uid=john smith,ou=people,dc=example,dc=com') }

      it 'finds the identity when the DN is formatted differently' do
        identity = described_class.with_extern_uid('ldapmain', 'uid=John Smith, ou=People, dc=example, dc=com').first

        expect(identity).to eq(ldap_identity)
      end
    end

    context 'any other provider' do
      let!(:test_entity) { create(:identity, provider: 'test_provider', extern_uid: 'test_uid') }

      it 'the extern_uid lookup is case insensitive' do
        identity = described_class.with_extern_uid('test_provider', 'TEST_UID').first

        expect(identity).to eq(test_entity)
      end
    end
  end

  describe '.with_any_extern_uid' do
    context 'provider with extern uid' do
      let!(:test_entity) { create(:identity, provider: 'test_provider', extern_uid: 'test_uid') }

      it 'finds any extern uids associated with a provider' do
        identity = described_class.with_any_extern_uid('test_provider').first

        expect(identity).to be_present
      end
    end

    context 'provider with nil extern uid' do
      let!(:nil_entity) { create(:identity, provider: 'nil_entity_provider', extern_uid: nil) }

      it 'has no results when there are no extern uids' do
        identity = described_class.with_any_extern_uid('nil_entity_provider').first

        expect(identity).to be_nil
      end
    end

    context 'no provider' do
      it 'has no results when there is no associated provider' do
        identity = described_class.with_any_extern_uid('nonexistent_provider').first

        expect(identity).to be_nil
      end
    end
  end

  context 'callbacks' do
    context 'before_save' do
      describe 'normalizes extern uid' do
        let!(:ldap_identity) { create(:identity, provider: 'ldapmain', extern_uid: 'uid=john smith,ou=people,dc=example,dc=com') }

        it 'if extern_uid changes' do
          expect(ldap_identity).not_to receive(:ensure_normalized_extern_uid)
          ldap_identity.save!
        end

        it 'if current_uid is nil' do
          expect(ldap_identity).to receive(:ensure_normalized_extern_uid)

          ldap_identity.update!(extern_uid: nil)

          expect(ldap_identity.extern_uid).to be_nil
        end

        it 'if extern_uid changed and not nil' do
          ldap_identity.update!(extern_uid: 'uid=john1,ou=PEOPLE,dc=example,dc=com')

          expect(ldap_identity.extern_uid).to eq 'uid=john1,ou=people,dc=example,dc=com'
        end
      end
    end

    context 'after_destroy' do
      let!(:user) { create(:user) }
      let(:ldap_identity) { create(:identity, provider: 'ldapmain', extern_uid: 'uid=john smith,ou=people,dc=example,dc=com', user: user) }
      let(:ldap_user_synced_attributes) { { provider: 'ldapmain', name_synced: true, email_synced: true } }
      let(:other_provider_user_synced_attributes) { { provider: 'other', name_synced: true, email_synced: true } }

      describe 'if user synced attributes metadada provider' do
        context 'matches the identity provider ' do
          it 'removes the user synced attributes' do
            user.create_user_synced_attributes_metadata(ldap_user_synced_attributes)

            expect(user.user_synced_attributes_metadata.provider).to eq 'ldapmain'

            ldap_identity.destroy!

            expect(user.reload.user_synced_attributes_metadata).to be_nil
          end
        end

        context 'does not matche the identity provider' do
          it 'does not remove the user synced attributes' do
            user.create_user_synced_attributes_metadata(other_provider_user_synced_attributes)

            expect(user.user_synced_attributes_metadata.provider).to eq 'other'

            ldap_identity.destroy!

            expect(user.reload.user_synced_attributes_metadata.provider).to eq 'other'
          end
        end
      end
    end
  end
end
