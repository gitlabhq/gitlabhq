# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateProtectionRules::UpdateRuleService, '#execute',
  feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:protection_rule) do
    create(:terraform_state_protection_rule, project: project,
      state_name: 'production',
      minimum_access_level_for_write: :maintainer,
      allowed_from: :anywhere)
  end

  let(:current_user) { maintainer }
  let(:params) do
    {
      state_name: 'staging',
      minimum_access_level_for_write: 'owner',
      allowed_from: 'ci_only'
    }
  end

  let(:service) { described_class.new(protection_rule, current_user: current_user, params: params) }

  subject(:service_execute) { service.execute }

  shared_examples 'a successful service response' do
    it 'returns success' do
      expect(service_execute).to be_success
      expect(service_execute.payload[:terraform_state_protection_rule]).to be_a(Terraform::StateProtectionRule)
    end

    it 'does not change the count' do
      expect { service_execute }.not_to change { Terraform::StateProtectionRule.count }
    end
  end

  shared_examples 'an erroneous service response' do |message: nil|
    it 'returns error' do
      result = service_execute
      expect(result).to be_error
      expect(result.message).to include(*Array(message)) if message
      expect(result.payload[:terraform_state_protection_rule]).to be_nil
    end

    it 'does not change the count' do
      expect { service_execute }.not_to change { Terraform::StateProtectionRule.count }
    end

    it 'does not change the rule' do
      expect { service_execute }.not_to change { protection_rule.reload.updated_at }
    end
  end

  context 'with valid params' do
    it_behaves_like 'a successful service response'

    it 'updates the rule with correct attributes' do
      service_execute
      protection_rule.reload

      expect(protection_rule).to have_attributes(
        state_name: 'staging',
        minimum_access_level_for_write: 'owner',
        allowed_from: 'ci_only'
      )
    end
  end

  context 'with empty params' do
    let(:params) { {} }

    it_behaves_like 'a successful service response'

    it 'does not change the rule' do
      expect { service_execute }.not_to change { protection_rule.reload.updated_at }
    end
  end

  context 'without params' do
    let(:service) { described_class.new(protection_rule, current_user: current_user) }

    it_behaves_like 'a successful service response'
  end

  context 'with invalid state_name' do
    let(:params) { { state_name: '' } }

    it_behaves_like 'an erroneous service response'
  end

  context 'with duplicate state_name' do
    before do
      create(:terraform_state_protection_rule, project: project, state_name: 'staging')
    end

    let(:params) { { state_name: 'staging' } }

    it_behaves_like 'an erroneous service response'
  end

  context 'with disallowed params' do
    let(:params) { super().merge(project_id: 999, unsupported_param: 'value') }

    it_behaves_like 'a successful service response'
  end

  context 'when current user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'an erroneous service response',
        message: 'Unauthorized to update a Terraform state protection rule'
    end
  end

  context 'without protection_rule' do
    it 'raises ArgumentError' do
      expect { described_class.new(nil, current_user: current_user, params: params) }
        .to raise_error(ArgumentError)
    end
  end

  context 'without current_user' do
    it 'raises ArgumentError' do
      expect { described_class.new(protection_rule, current_user: nil, params: params) }
        .to raise_error(ArgumentError)
    end
  end
end
