# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::CommandPolicy, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project) }

  subject(:policy) { described_class.new(user, command) }

  describe 'delegation' do
    it { is_expected.to delegate_to(::ProjectPolicy) }
  end
end
