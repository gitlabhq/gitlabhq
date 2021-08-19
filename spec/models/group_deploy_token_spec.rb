# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployToken, type: :model do
  let_it_be(:group) { create(:group) }
  let_it_be(:deploy_token) { create(:deploy_token) }
  let_it_be(:group_deploy_token) { create(:group_deploy_token, group: group, deploy_token: deploy_token) }

  describe 'relationships' do
    it { is_expected.to belong_to :group }
    it { is_expected.to belong_to :deploy_token }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of :deploy_token }
    it { is_expected.to validate_presence_of :group }
    it { is_expected.to validate_uniqueness_of(:deploy_token_id).scoped_to(:group_id) }
  end

  describe '#has_access_to_group?' do
    subject { group_deploy_token.has_access_to_group?(test_group) }

    context 'for itself' do
      let(:test_group) { group }

      it { is_expected.to eq(true) }
    end

    context 'for a subgroup' do
      let(:test_group) { create(:group, parent: group) }

      it { is_expected.to eq(true) }
    end

    context 'for other group' do
      let(:test_group) { create(:group) }

      it { is_expected.to eq(false) }
    end
  end
end
