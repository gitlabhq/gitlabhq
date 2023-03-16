# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::RunnerMachinePolicyPreloader, feature_category: :runner_fleet do
  let_it_be(:user) { create(:user) }
  let_it_be(:runner1) { create(:ci_runner) }
  let_it_be(:runner2) { create(:ci_runner) }
  let_it_be(:runner_machine1) { create(:ci_runner_machine, runner: runner1) }
  let_it_be(:runner_machine2) { create(:ci_runner_machine, runner: runner2) }

  let(:base_runner_machines) do
    Project.where(id: [runner_machine1, runner_machine2])
  end

  it 'avoids N+1 queries when authorizing a list of runner machines', :request_store do
    preload_runner_machines_for_policy(user)
    control = ActiveRecord::QueryRecorder.new { authorize_all_runner_machines(user) }

    new_runner1 = create(:ci_runner)
    new_runner2 = create(:ci_runner)
    new_runner_machine1 = create(:ci_runner_machine, runner: new_runner1)
    new_runner_machine2 = create(:ci_runner_machine, runner: new_runner2)

    pristine_runner_machines = Project.where(id: base_runner_machines + [new_runner_machine1, new_runner_machine2])

    preload_runner_machines_for_policy(user, pristine_runner_machines)
    expect { authorize_all_runner_machines(user, pristine_runner_machines) }.not_to exceed_query_limit(control)
  end

  def authorize_all_runner_machines(current_user, runner_machine_list = base_runner_machines)
    runner_machine_list.each { |runner_machine| current_user.can?(:read_runner_machine, runner_machine) }
  end

  def preload_runner_machines_for_policy(current_user, runner_machine_list = base_runner_machines)
    described_class.new(runner_machine_list, current_user).execute
  end
end
