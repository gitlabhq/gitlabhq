# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserHighestRole, feature_category: :plan_provisioning do
  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:highest_access_level).in_array(Gitlab::Access.all_values).allow_nil }
  end

  describe 'scopes' do
    describe '.with_highest_access_level' do
      let(:developer_access_level) { Gitlab::Access::DEVELOPER }
      let!(:developer) { create(:user_highest_role, :developer) }
      let!(:another_developer) { create(:user_highest_role, :developer) }
      let!(:maintainer) { create(:user_highest_role, :maintainer) }

      it 'only returns entry for developer access level' do
        expect(described_class.with_highest_access_level(developer_access_level)).to contain_exactly(
          developer,
          another_developer
        )
      end
    end
  end

  describe '.allowed_values' do
    let(:expected_allowed_values) do
      [
        Gitlab::Access::GUEST,
        Gitlab::Access::PLANNER,
        Gitlab::Access::REPORTER,
        Gitlab::Access::DEVELOPER,
        Gitlab::Access::MAINTAINER,
        Gitlab::Access::OWNER
      ]
    end

    it 'returns all access values' do
      expected_allowed_values << Gitlab::Access::MINIMAL_ACCESS if Gitlab.ee?

      expect(::UserHighestRole.allowed_values).to eq(expected_allowed_values)
    end
  end
end
