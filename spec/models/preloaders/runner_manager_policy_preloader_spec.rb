# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::RunnerManagerPolicyPreloader, feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }
  let_it_be(:runner1) { create(:ci_runner) }
  let_it_be(:runner2) { create(:ci_runner) }
  let_it_be(:runner_manager1) { create(:ci_runner_machine, runner: runner1) }
  let_it_be(:runner_manager2) { create(:ci_runner_machine, runner: runner2) }

  let(:base_runner_managers) do
    Project.where(id: [runner_manager1, runner_manager2])
  end

  it 'avoids N+1 queries when authorizing a list of runner managers', :request_store do
    preload_runner_managers_for_policy(user)
    control = ActiveRecord::QueryRecorder.new { authorize_all_runner_managers(user) }

    new_runner1 = create(:ci_runner)
    new_runner2 = create(:ci_runner)
    new_runner_manager1 = create(:ci_runner_machine, runner: new_runner1)
    new_runner_manager2 = create(:ci_runner_machine, runner: new_runner2)

    pristine_runner_managers = Project.where(id: base_runner_managers + [new_runner_manager1, new_runner_manager2])

    preload_runner_managers_for_policy(user, pristine_runner_managers)
    expect { authorize_all_runner_managers(user, pristine_runner_managers) }.not_to exceed_query_limit(control)
  end

  def authorize_all_runner_managers(current_user, runner_manager_list = base_runner_managers)
    runner_manager_list.each { |runner_manager| current_user.can?(:read_runner_manager, runner_manager) }
  end

  def preload_runner_managers_for_policy(current_user, runner_manager_list = base_runner_managers)
    described_class.new(runner_manager_list, current_user).execute
  end
end
