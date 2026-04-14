# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CommandPolicy, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project) }

  subject(:policy) { described_class.new(user, command) }

  describe 'delegation' do
    let(:delegations) { policy.delegated_policies }

    it 'delegates to ProjectPolicy' do
      expect(delegations.size).to eq(1)

      delegations.each_value do |delegated_policy|
        expect(delegated_policy).to be_instance_of(ProjectPolicy)
      end
    end
  end
end
