# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUser, type: :model, feature_category: :cell do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_users).required }
    it { is_expected.to belong_to(:user).inverse_of(:organization_users).required }
  end

  describe 'validations' do
    subject { build(:organization_user) }

    it { is_expected.to define_enum_for(:access_level).with_values(described_class.access_levels) }
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:organization_id) }

    it 'does not allow invalid enum value' do
      expect { build(:organization_user, access_level: '_invalid_') }.to raise_error(ArgumentError)
    end

    context 'when changing access level of owner' do
      let_it_be(:organization_user) { create(:organization_owner) }

      context 'when user is the last owner' do
        context 'when assigning lower access level' do
          it 'raises validation error' do
            error_message = _('Validation failed: You cannot change the access of the last owner from the organization')

            expect { organization_user.update!(access_level: 'default') }
              .to raise_error(ActiveRecord::RecordInvalid, error_message)
          end
        end

        context 'when assigning access to same level' do
          it 'does not raise validation error' do
            expect { organization_user.update!(access_level: 'owner') }.not_to raise_error
          end
        end
      end

      context 'when organization has multiple owners' do
        let_it_be(:other_owner) { create(:organization_owner, organization: organization_user.organization) }

        it 'does not raise validation error' do
          expect { organization_user.update!(access_level: 'default') }.not_to raise_error
        end
      end
    end

    context 'on destroy' do
      let(:user) { create(:user, :without_default_org) }

      subject(:organization_user) { create(:organization_user, user: user) }

      it 'prevents user leaving all organizations' do
        organization_user.destroy!

        expect(organization_user.errors[:base]).to include(_('A user must associate with at least one organization'))
      end

      context 'when user is in multiple organizations' do
        let!(:other_organization_user) { create(:organization_user, user: user) }

        it 'does not prevent user from leaving organization' do
          organization_user.destroy!

          expect(organization_user.errors[:base]).to be_empty
        end
      end

      context 'when user is destroyed' do
        it 'destroys the organization_user record' do
          organization_user_id = organization_user.id

          user.destroy!

          expect(described_class.exists?(organization_user_id)).to be_falsy
        end
      end
    end
  end

  context 'with loose foreign key on organization_users.organization_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:organization) }
      let_it_be(:model) { create(:organization_user, organization: parent) }
    end
  end

  describe 'scopes' do
    describe '.owners' do
      it 'returns the owners of the organization' do
        organization_user = create(:organization_user, :owner)
        create(:organization_user)

        expect(described_class.owners).to match([organization_user])
      end
    end

    describe '.in_organization' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:organization_users) { create_pair(:organization_user, organization: organization) }

      before do
        create(:organization_user)
      end

      subject { described_class.in_organization(organization) }

      it { is_expected.to match_array(organization_users) }
    end

    describe '#with_active_users' do
      let_it_be(:active_organization_user) { create(:organization_user) }
      let_it_be(:inactive_organization_user) { create(:organization_user) { |org_user| org_user.user.block! } }

      subject(:active_user) { described_class.with_active_users }

      it { is_expected.to include(active_organization_user).and exclude(inactive_organization_user) }
    end

    describe '.by_user' do
      let_it_be(:user) { create(:user) }
      let_it_be(:another_user) { create(:user) }
      let_it_be(:organization_1) { create(:organization, users: [user]) }
      let_it_be(:organization_2) { create(:organization, users: [user, another_user]) }
      let_it_be(:organization_3) { create(:organization, users: [another_user]) }

      subject(:scope_by_user) { described_class.by_user(user) }

      it 'returns the records for the user' do
        expect(scope_by_user.map(&:organization)).to contain_exactly(
          organization_1, organization_2
        )
      end
    end
  end

  it_behaves_like 'having unique enum values'

  describe '.create_default_organization_record_for' do
    let_it_be(:user) { create(:user, :without_default_org) }
    let(:user_is_admin) { false }
    let(:user_id) { user.id }

    subject(:create_entry) do
      described_class.create_default_organization_record_for(user_id, user_is_admin: user_is_admin)
    end

    context 'when default organization does not exist' do
      it 'does not create a recored' do
        expect { create_entry }.not_to change { described_class.count }
      end
    end

    context 'when default organization exist' do
      let_it_be(:default_organization) { create(:organization, :default) }

      context 'when creating as as default user' do
        it 'creates record with correct attributes' do
          expect { create_entry }.to change { described_class.count }.by(1)
          expect(default_organization.user?(user)).to be(true)
        end
      end

      context 'when creating as an owner' do
        let(:user_is_admin) { true }

        it 'creates record with correct attributes' do
          expect { create_entry }.to change { described_class.count }.by(1)
          expect(default_organization.owner?(user)).to be(true)
        end
      end

      context 'when entry already exists' do
        let_it_be(:organization_user) { create(:organization_user, user: user, organization: default_organization) }

        it 'does not create or update existing record' do
          expect { create_entry }.not_to change { described_class.count }
        end

        context 'when access_level changes' do
          let(:user_is_admin) { true }

          it 'changes access_level on the existing record' do
            expect(default_organization.owner?(user)).to be(false)

            expect { create_entry }.not_to change { described_class.count }

            expect(default_organization.owner?(user)).to be(true)
          end
        end
      end

      context 'when creating with invalid user_id' do
        let(:user_id) { nil }

        it 'raises and error' do
          expect { create_entry }.to raise_error(ActiveRecord::NotNullViolation)
        end
      end
    end
  end

  describe '.default_organization_access_level' do
    let(:user_is_admin) { true }

    subject { described_class.default_organization_access_level(user_is_admin: user_is_admin) }

    context 'when user is admin' do
      it { is_expected.to eq(:owner) }
    end

    context 'when user is not admin' do
      let(:user_is_admin) { false }

      it { is_expected.to eq(:default) }
    end
  end

  describe '.create_organization_record_for' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:user) { create(:user, :without_default_org) }
    let_it_be(:user_id) { user.id }
    let_it_be(:organization_id) { organization.id }

    subject(:create_organization_record) do
      described_class.create_organization_record_for(user_id, organization_id)
    end

    context 'when record already exists' do
      let_it_be(:existing_record) do
        create(:organization_user, :owner, organization_id: organization_id, user_id: user_id)
      end

      it 'returns existing record without access_level change' do
        expect { create_organization_record }.not_to change { described_class.count }
        expect(organization.owner?(user)).to be(true)
      end

      context 'with race condition handling of already existing record' do
        it 'performs the upsert without error' do
          expect(described_class).to receive(:find_by).and_return(nil)

          expect { create_organization_record }.not_to change { described_class.count }
          expect(organization.owner?(user)).to be(true)
        end
      end
    end

    context 'when no existing record exists' do
      it 'creates a new record with default access_level' do
        expect { create_organization_record }.to change { described_class.count }.by(1)
        expect(organization.user?(user)).to be(true)
        expect(organization.owner?(user)).to be(false)
      end
    end
  end

  describe '#last_owner?' do
    subject(:last_owner?) { organization_user.last_owner? }

    context 'when user is not the owner' do
      let(:organization_user) { build(:organization_user) }

      it { is_expected.to eq(false) }
    end

    context 'when user is the owner' do
      let_it_be(:organization_user, reload: true) { create(:organization_owner) }
      let_it_be(:organization) { organization_user.organization }

      context 'when another owner does not exist' do
        it { is_expected.to eq(true) }
      end

      context 'when another owner exists' do
        let_it_be(:another_owner, reload: true) { create(:organization_owner, organization: organization) }

        where(:current_owner_active?, :another_owner_active?, :last_owner?) do
          true  | true  | false
          true  | false | true
          false | true  | false
          false | false | false
        end

        with_them do
          before do
            organization_user.user.block! unless current_owner_active?
            another_owner.user.block! unless another_owner_active?
          end

          it { is_expected.to eq(last_owner?) }
        end
      end
    end
  end
end
