# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateProtectionRulePolicy, feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:protection_rule) { create(:terraform_state_protection_rule, project: project) }

  subject { described_class.new(user, protection_rule) }

  describe 'rules' do
    context 'without access' do
      let_it_be(:user) { create(:user) }

      it { expect_disallowed(:read_terraform_state) }
      it { expect_disallowed(:admin_terraform_state) }
    end

    context 'as a developer' do
      let_it_be(:user) { create(:user, developer_of: project) }

      it { expect_allowed(:read_terraform_state) }
      it { expect_disallowed(:admin_terraform_state) }
    end

    context 'as a maintainer' do
      let_it_be(:user) { create(:user, maintainer_of: project) }

      it { expect_allowed(:read_terraform_state) }
      it { expect_allowed(:admin_terraform_state) }
    end
  end
end
