# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Maven::UpstreamPolicy, feature_category: :virtual_registry do
  let_it_be(:upstream) { create(:virtual_registries_packages_maven_upstream) }

  let(:user) { upstream.group.first_owner }

  subject(:policy) { described_class.new(user, upstream) }

  describe 'delegation' do
    let(:delegations) { policy.delegated_policies }

    it 'delegates to the registry policy' do
      expect(delegations.size).to eq(1)

      delegations.each_value do |delegated_policy|
        expect(delegated_policy).to be_instance_of(::VirtualRegistries::Packages::Maven::RegistryPolicy)
      end
    end
  end
end
