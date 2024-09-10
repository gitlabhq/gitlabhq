# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerManagerPolicy, feature_category: :fleet_visibility do
  let_it_be(:owner) { create(:user) }

  describe 'ability :read_runner_manager' do
    let(:runner_manager) { runner.runner_managers.first }

    subject(:policy) { described_class.new(user, runner_manager) }

    it_behaves_like 'runner read policy', :read_runner_manager
  end
end
