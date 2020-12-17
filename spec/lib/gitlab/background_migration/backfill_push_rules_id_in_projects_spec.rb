# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPushRulesIdInProjects, :migration, schema: 2020_03_25_162730 do
  let(:push_rules) { table(:push_rules) }
  let(:projects) { table(:projects) }
  let(:project_settings) { table(:project_settings) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }

  subject { described_class.new }

  describe '#perform' do
    it 'creates new project push_rules for all push rules in the range' do
      project_1 = projects.create!(id: 1, namespace_id: namespace.id)
      project_2 = projects.create!(id: 2, namespace_id: namespace.id)
      project_3 = projects.create!(id: 3, namespace_id: namespace.id)
      project_settings_1 = project_settings.create!(project_id: project_1.id)
      project_settings_2 = project_settings.create!(project_id: project_2.id)
      project_settings_3 = project_settings.create!(project_id: project_3.id)
      push_rule_1 = push_rules.create!(id: 5, is_sample: false, project_id: project_1.id)
      push_rule_2 = push_rules.create!(id: 6, is_sample: false, project_id: project_2.id)
      push_rules.create!(id: 8, is_sample: false, project_id: 3)

      subject.perform(5, 7)

      expect(project_settings_1.reload.push_rule_id).to eq(push_rule_1.id)
      expect(project_settings_2.reload.push_rule_id).to eq(push_rule_2.id)
      expect(project_settings_3.reload.push_rule_id).to be_nil
    end
  end
end
