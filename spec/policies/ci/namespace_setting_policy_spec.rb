# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::NamespaceSettingPolicy, feature_category: :pipeline_composition do
  subject(:policy) { described_class.new(user, namespace_setting) }

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:namespace_setting) { build(:namespace_settings, namespace: namespace) }

  describe 'delegation' do
    let(:delegations) { policy.delegated_policies }

    it 'delegates to UserNamespacePolicy' do
      expect(delegations.size).to eq(1)

      delegations.each_value do |delegated_policy|
        expect(delegated_policy).to be_instance_of(::Namespaces::UserNamespacePolicy)
      end
    end
  end
end
