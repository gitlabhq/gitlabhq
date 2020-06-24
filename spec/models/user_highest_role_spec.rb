# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserHighestRole do
  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:highest_access_level).in_array([nil, *Gitlab::Access.all_values]) }
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
end
