# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerManagerPolicy, feature_category: :fleet_visibility do
  let_it_be(:owner) { create(:user) }

  subject(:policy) { described_class.new(user, runner_manager) }

  describe 'ability :read_runner_manager' do
    let(:runner_manager) { runner.runner_managers.first }

    include_context 'with runner policy environment'

    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :read_runner_manager
    it_behaves_like 'runner policy', :read_runner_manager
  end
end
