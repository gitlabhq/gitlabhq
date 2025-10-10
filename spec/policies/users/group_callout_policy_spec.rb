# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GroupCalloutPolicy, feature_category: :shared do
  let_it_be(:group_callout) { create(:group_callout) }
  let(:user) { group_callout.user }

  subject(:policy) { described_class.new(user, group_callout) }

  describe 'delegation' do
    let(:delegations) { policy.delegated_policies }

    it 'delegates to UserPolicy' do
      expect(delegations.size).to eq(1)

      delegations.each_value do |delegated_policy|
        expect(delegated_policy).to be_instance_of(::UserPolicy)
      end
    end
  end
end
