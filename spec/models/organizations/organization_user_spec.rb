# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUser, type: :model, feature_category: :cell do
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
  end

  context 'with loose foreign key on organization_users.organization_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:organization) }
      let_it_be(:model) { create(:organization_user, organization: parent) }
    end
  end

  context 'with loose foreign key on organization_users.user_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) { create(:organization_user, user: parent) }
    end
  end

  describe '.owners' do
    it 'returns the owners of the organization' do
      organization_user = create(:organization_user, :owner)
      create(:organization_user)

      expect(described_class.owners).to match([organization_user])
    end
  end

  it_behaves_like 'having unique enum values'

  describe '.create_default_organization_record_for' do
    let_it_be(:default_organization) { create(:organization, :default) }
    let_it_be(:user) { create(:user, :without_default_org) }
    let(:access_level) { :default }
    let(:user_id) { user.id }

    subject(:create_entry) { described_class.create_default_organization_record_for(user_id, access_level) }

    context 'when creating as as default user' do
      it 'creates record with correct attributes' do
        expect { create_entry }.to change { described_class.count }.by(1)
        expect(default_organization.user?(user)).to be(true)
      end
    end

    context 'when creating as an owner' do
      let(:access_level) { :owner }

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
        let(:access_level) { :owner }

        it 'changes access_level on the existing record' do
          expect(default_organization.owner?(user)).to be(false)

          expect { create_entry }.not_to change { described_class.count }

          expect(default_organization.owner?(user)).to be(true)
        end
      end
    end

    context 'when creating with invalid access_level' do
      let(:access_level) { :foo }

      it 'raises and error' do
        expect { create_entry }.to raise_error(ActiveRecord::NotNullViolation)
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
