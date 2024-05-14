# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateVersionPolicy do
  let_it_be(:project) { create(:project) }
  let_it_be(:terraform_state) { create(:terraform_state, :with_version, project: project) }

  subject { described_class.new(user, terraform_state.latest_version) }

  describe 'rules' do
    context 'no access' do
      let(:user) { create(:user) }

      it { is_expected.to be_disallowed(:read_terraform_state) }
      it { is_expected.to be_disallowed(:admin_terraform_state) }
    end

    context 'developer' do
      let(:user) { create(:user, developer_of: project) }

      it { is_expected.to be_allowed(:read_terraform_state) }
      it { is_expected.to be_disallowed(:admin_terraform_state) }
    end

    context 'maintainer' do
      let(:user) { create(:user, maintainer_of: project) }

      it { is_expected.to be_allowed(:read_terraform_state) }
      it { is_expected.to be_allowed(:admin_terraform_state) }
    end
  end
end
