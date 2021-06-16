# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillEscalationPoliciesForOncallSchedules do
  let_it_be(:projects) { table(:projects) }
  let_it_be(:schedules) { table(:incident_management_oncall_schedules) }
  let_it_be(:policies) { table(:incident_management_escalation_policies) }
  let_it_be(:rules) { table(:incident_management_escalation_rules) }

  # Project with no schedules
  let_it_be(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab') }
  let_it_be(:project_a) { projects.create!(namespace_id: namespace.id) }

  context 'with backfill-able schedules' do
    # Project with one schedule
    let_it_be(:project_b) { projects.create!(namespace_id: namespace.id) }
    let_it_be(:schedule_b1) { schedules.create!(project_id: project_b.id, iid: 1, name: 'Schedule B1') }

    # Project with multiple schedules
    let_it_be(:project_c) { projects.create!(namespace_id: namespace.id) }
    let_it_be(:schedule_c1) { schedules.create!(project_id: project_c.id, iid: 1, name: 'Schedule C1') }
    let_it_be(:schedule_c2) { schedules.create!(project_id: project_c.id, iid: 2, name: 'Schedule C2') }

    # Project with a single schedule which already has a policy
    let_it_be(:project_d) { projects.create!(namespace_id: namespace.id) }
    let_it_be(:schedule_d1) { schedules.create!(project_id: project_d.id, iid: 1, name: 'Schedule D1') }
    let_it_be(:policy_d1) { policies.create!(project_id: project_d.id, name: 'Policy D1') }
    let_it_be(:rule_d1) { rules.create!(policy_id: policy_d1.id, oncall_schedule_id: schedule_d1.id, status: 2, elapsed_time_seconds: 60) }

    # Project with a multiple schedule, one of which already has a policy
    let_it_be(:project_e) { projects.create!(namespace_id: namespace.id) }
    let_it_be(:schedule_e1) { schedules.create!(project_id: project_e.id, iid: 1, name: 'Schedule E1') }
    let_it_be(:schedule_e2) { schedules.create!(project_id: project_e.id, iid: 2, name: 'Schedule E2') }
    let_it_be(:policy_e1) { policies.create!(project_id: project_e.id, name: 'Policy E1') }
    let_it_be(:rule_e1) { rules.create!(policy_id: policy_e1.id, oncall_schedule_id: schedule_e2.id, status: 2, elapsed_time_seconds: 60) }

    # Project with a multiple schedule, with multiple policies
    let_it_be(:project_f) { projects.create!(namespace_id: namespace.id) }
    let_it_be(:schedule_f1) { schedules.create!(project_id: project_f.id, iid: 1, name: 'Schedule F1') }
    let_it_be(:schedule_f2) { schedules.create!(project_id: project_f.id, iid: 2, name: 'Schedule F2') }
    let_it_be(:policy_f1) { policies.create!(project_id: project_f.id, name: 'Policy F1') }
    let_it_be(:rule_f1) { rules.create!(policy_id: policy_f1.id, oncall_schedule_id: schedule_f1.id, status: 2, elapsed_time_seconds: 60) }
    let_it_be(:rule_f2) { rules.create!(policy_id: policy_f1.id, oncall_schedule_id: schedule_f2.id, status: 2, elapsed_time_seconds: 60) }
    let_it_be(:policy_f2) { policies.create!(project_id: project_f.id, name: 'Policy F2') }
    let_it_be(:rule_f3) { rules.create!(policy_id: policy_f2.id, oncall_schedule_id: schedule_f2.id, status: 1, elapsed_time_seconds: 10) }

    it 'backfills escalation policies correctly' do
      expect { migrate! }
        .to change(policies, :count).by(2)
        .and change(rules, :count).by(3)

      new_policy_b1, new_policy_c1 = new_polices = policies.last(2)
      new_rules = rules.last(3)

      expect(new_polices).to all have_attributes(name: 'On-call Escalation Policy')
      expect(new_policy_b1.description).to eq('Immediately notify Schedule B1')
      expect(new_policy_c1.description).to eq('Immediately notify Schedule C1')
      expect(policies.pluck(:project_id)).to eq([
        project_d.id,
        project_e.id,
        project_f.id,
        project_f.id,
        project_b.id,
        project_c.id
      ])

      expect(new_rules).to all have_attributes(status: 1, elapsed_time_seconds: 0)
      expect(rules.pluck(:policy_id)).to eq([
        rule_d1.policy_id,
        rule_e1.policy_id,
        rule_f1.policy_id,
        rule_f2.policy_id,
        rule_f3.policy_id,
        new_policy_b1.id,
        new_policy_c1.id,
        new_policy_c1.id
      ])
      expect(rules.pluck(:oncall_schedule_id)).to eq([
        rule_d1.oncall_schedule_id,
        rule_e1.oncall_schedule_id,
        rule_f1.oncall_schedule_id,
        rule_f2.oncall_schedule_id,
        rule_f3.oncall_schedule_id,
        schedule_b1.id,
        schedule_c1.id,
        schedule_c2.id
      ])
    end
  end

  context 'with no schedules' do
    it 'does nothing' do
      expect { migrate! }
        .to not_change(policies, :count)
        .and not_change(rules, :count)
    end
  end
end
