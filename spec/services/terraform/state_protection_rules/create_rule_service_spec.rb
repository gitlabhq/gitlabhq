# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateProtectionRules::CreateRuleService, '#execute',
  feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:current_user) { maintainer }
  let(:params) do
    {
      state_name: 'production',
      minimum_access_level_for_write: 'maintainer',
      allowed_from: 'ci_only'
    }
  end

  let(:service) { described_class.new(project: project, current_user: current_user, params: params) }

  subject(:service_execute) { service.execute }

  shared_examples 'a successful service response' do
    it_behaves_like 'returning a success service response' do
      it 'returns the created protection rule in payload' do
        is_expected.to have_attributes(
          payload: { terraform_state_protection_rule: be_a(Terraform::StateProtectionRule).and(be_persisted) }
        )
      end
    end

    it 'creates a protection rule' do
      expect { service_execute }.to change { Terraform::StateProtectionRule.count }.by(1)
    end
  end

  shared_examples 'an erroneous service response' do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it { is_expected.to have_attributes(payload: { terraform_state_protection_rule: nil }) }
    end

    it 'does not create a protection rule' do
      expect { service_execute }.not_to change { Terraform::StateProtectionRule.count }
    end
  end

  context 'with valid params' do
    it_behaves_like 'a successful service response'

    it 'creates the rule with correct attributes' do
      service_execute
      rule = Terraform::StateProtectionRule.last

      expect(rule).to have_attributes(
        project: project,
        state_name: 'production',
        minimum_access_level_for_write: 'maintainer',
        allowed_from: 'ci_only'
      )
    end
  end

  context 'with invalid params' do
    let(:params) { { state_name: '', minimum_access_level_for_write: 'maintainer' } }

    it_behaves_like 'an erroneous service response'
  end

  context 'with duplicate state_name for same project' do
    before do
      create(:terraform_state_protection_rule, project: project, state_name: 'production')
    end

    it_behaves_like 'an erroneous service response'
  end

  context 'with disallowed params' do
    let(:params) { super().merge(project_id: 999, unsupported_param: 'value') }

    it_behaves_like 'a successful service response'
  end

  context 'when current user is a developer (unauthorized)' do
    let(:current_user) { developer }

    it_behaves_like 'an erroneous service response',
      message: 'Unauthorized to create a Terraform state protection rule'
  end

  context 'with invalid enum value for minimum_access_level_for_write' do
    let(:params) { super().merge(minimum_access_level_for_write: 'invalid_value') }

    it_behaves_like 'an erroneous service response',
      message: "'invalid_value' is not a valid minimum_access_level_for_write"
  end

  context 'when the database raises StatementInvalid' do
    before do
      allow(project.terraform_state_protection_rules)
        .to receive(:create)
        .and_raise(ActiveRecord::StatementInvalid, 'PG::Error: boom')
    end

    it_behaves_like 'an erroneous service response', message: 'PG::Error: boom'
  end
end
