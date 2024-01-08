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
end
