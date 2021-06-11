# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangePackagesSizeDefaultsInProjectStatistics do
  let(:project_statistics) { table(:project_statistics) }
  let(:projects)           { table(:projects) }

  it 'removes null packages_size' do
    stats_to_migrate = 10

    stats_to_migrate.times do |i|
      p = projects.create!(name: "project #{i}", namespace_id: 1)
      project_statistics.create!(project_id: p.id, namespace_id: p.namespace_id)
    end

    expect { migrate! }
      .to change { ProjectStatistics.where(packages_size: nil).count }
            .from(stats_to_migrate)
            .to(0)
  end

  it 'defaults packages_size to 0' do
    project = projects.create!(name: 'a new project', namespace_id: 2)
    stat = project_statistics.create!(project_id: project.id, namespace_id: project.namespace_id)

    expect(stat.packages_size).to be_nil

    migrate!

    stat.reload
    expect(stat.packages_size).to eq(0)
  end
end
