# frozen_string_literal: true

require 'spec_helper'

require_migration!('operations_feature_flags_correct_flexible_rollout_values')

RSpec.describe OperationsFeatureFlagsCorrectFlexibleRolloutValues, :migration do
  let_it_be(:strategies) { table(:operations_strategies) }

  let(:namespace) { table(:namespaces).create!(name: 'feature_flag', path: 'feature_flag') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let(:feature_flag) { table(:operations_feature_flags).create!(project_id: project.id, active: true, name: 'foo', iid: 1) }

  describe "#up" do
    described_class::STICKINESS.each do |old, new|
      it "corrects parameters for flexible rollout stickiness #{old}" do
        reversible_migration do |migration|
          parameters = { groupId: "default", rollout: "100", stickiness: old }
          strategy = create_strategy(parameters)

          migration.before -> {
            expect(strategy.reload.parameters).to eq({ "groupId" => "default", "rollout" => "100", "stickiness" => old })
          }

          migration.after -> {
            expect(strategy.reload.parameters).to eq({ "groupId" => "default", "rollout" => "100", "stickiness" => new })
          }
        end
      end
    end

    it 'ignores other strategies' do
      reversible_migration do |migration|
        parameters = { "groupId" => "default", "rollout" => "100", "stickiness" => "USERID" }
        strategy = create_strategy(parameters, name: 'default')

        migration.before -> {
          expect(strategy.reload.parameters).to eq(parameters)
        }

        migration.after -> {
          expect(strategy.reload.parameters).to eq(parameters)
        }
      end
    end

    it 'ignores other stickiness' do
      reversible_migration do |migration|
        parameters = { "groupId" => "default", "rollout" => "100", "stickiness" => "FOO" }
        strategy = create_strategy(parameters)

        migration.before -> {
          expect(strategy.reload.parameters).to eq(parameters)
        }

        migration.after -> {
          expect(strategy.reload.parameters).to eq(parameters)
        }
      end
    end
  end

  def create_strategy(params, name: 'flexibleRollout')
    strategies.create!(name: name, parameters: params, feature_flag_id: feature_flag.id)
  end
end
