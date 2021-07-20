# frozen_string_literal: true

require 'spec_helper'

require_migration!('cascade_delete_freeze_periods')

RSpec.describe CascadeDeleteFreezePeriods do
  let(:namespace) { table(:namespaces).create!(name: 'deploy_freeze', path: 'deploy_freeze') }
  let(:project) { table(:projects).create!(id: 1, namespace_id: namespace.id) }
  let(:freeze_periods) { table(:ci_freeze_periods) }

  describe "#up" do
    it 'allows for a project to be deleted' do
      freeze_periods.create!(id: 1, project_id: project.id, freeze_start: '5 * * * *', freeze_end: '6 * * * *', cron_timezone: 'UTC')
      migrate!

      project.delete

      expect(freeze_periods.where(project_id: project.id).count).to be_zero
    end
  end
end
