# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCurrentValueWithProgressWorkItemProgresses, :migration, feature_category: :team_planning do
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:progresses) { table(:work_item_progresses) }
  let(:issue_base_type_enum_value) { 5 }
  let(:issue_type) { table(:work_item_types).find_by!(namespace_id: nil, base_type: issue_base_type_enum_value) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, name: 'Alpha Gamma',
      path: 'alpha-gamma')
  end

  let(:work_item1) do
    issues.create!(
      id: 1, project_id: project.id, namespace_id: project.project_namespace_id,
      title: 'issue1', author_id: user.id, work_item_type_id: issue_type.id
    )
  end

  let(:work_item2) do
    issues.create!(
      id: 2, project_id: project.id, namespace_id: project.project_namespace_id,
      title: 'issue2', author_id: user.id, work_item_type_id: issue_type.id
    )
  end

  let(:progress1) { progresses.create!(issue_id: work_item1.id, progress: 10) }
  let(:progress2) { progresses.create!(issue_id: work_item2.id, progress: 60) }

  describe '#up' do
    it 'back fills current_value from progress columns' do
      expect { migrate! }
        .to change { progress1.reload.current_value }.from(0).to(10)
        .and change { progress2.reload.current_value }.from(0).to(60)
        .and not_change(progress1, :progress)
        .and not_change(progress2, :progress)
    end
  end
end
