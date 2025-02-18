# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ChangeVariablesService, feature_category: :ci_variables do
  let(:service) { described_class.new(container: group, current_user: user, params: params) }

  let_it_be(:user) { create(:user) }

  let(:group) { spy(:group, variables: []) }
  let(:params) { { variables_attributes: [{ key: 'new_variable', value: 'variable_value' }] } }

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'delegates to ActiveRecord update' do
      execute

      expect(group).to have_received(:update).with(params)
    end
  end
end
