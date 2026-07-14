# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::SquashOptions::BaseService, feature_category: :source_code_management do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:protected_branch) { create(:protected_branch, project: project) }

  let(:branch_rule) { ::Projects::BranchRule.new(project, protected_branch) }
  let(:squash_option) { ::Projects::BranchRules::SquashOption.squash_options['always'] }

  subject(:service) { described_class.new(branch_rule, user: user, params: { squash_option: squash_option }) }

  describe '#squash_option' do
    it 'reads the squash_option from params' do
      expect(service.send(:squash_option)).to eq(squash_option)
    end
  end

  describe '#execute_on_branch_rule' do
    it 'returns a not supported error', :aggregate_failures do
      response = service.send(:execute_on_branch_rule)

      expect(response).to be_error
      expect(response.message).to eq('Squash options are not supported for this branch rule')
    end
  end

  describe '#execute_on_all_branches_rule' do
    it 'returns a not supported error', :aggregate_failures do
      response = service.send(:execute_on_all_branches_rule)

      expect(response).to be_error
      expect(response.message).to eq('Squash options for all branches can only be changed using the update mutation')
    end
  end

  describe '#execute_on_all_protected_branches_rule' do
    it 'returns a not supported error', :aggregate_failures do
      response = service.send(:execute_on_all_protected_branches_rule)

      expect(response).to be_error
      expect(response.message).to eq('All protected branch rules cannot configure squash options')
      expect(response.payload[:errors]).to contain_exactly('All protected branches not allowed')
      expect(response.reason).to eq(:unprocessable_entity)
    end
  end
end
