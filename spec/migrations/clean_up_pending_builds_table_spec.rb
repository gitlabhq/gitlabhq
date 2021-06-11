# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanUpPendingBuildsTable do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:queue) { table(:ci_pending_builds) }
  let(:builds) { table(:ci_builds) }

  before do
    namespaces.create!(id: 123, name: 'sample', path: 'sample')
    projects.create!(id: 123, name: 'sample', path: 'sample', namespace_id: 123)

    builds.create!(id: 1, project_id: 123, status: 'pending', type: 'Ci::Build')
    builds.create!(id: 2, project_id: 123, status: 'pending', type: 'GenericCommitStatus')
    builds.create!(id: 3, project_id: 123, status: 'success', type: 'Ci::Bridge')
    builds.create!(id: 4, project_id: 123, status: 'success', type: 'Ci::Build')
    builds.create!(id: 5, project_id: 123, status: 'running', type: 'Ci::Build')
    builds.create!(id: 6, project_id: 123, status: 'created', type: 'Ci::Build')

    queue.create!(id: 1, project_id: 123, build_id: 1)
    queue.create!(id: 2, project_id: 123, build_id: 4)
    queue.create!(id: 3, project_id: 123, build_id: 5)
  end

  it 'removes duplicated data from pending builds table' do
    migrate!

    expect(queue.all.count).to eq 1
    expect(queue.first.id).to eq 1
    expect(builds.all.count).to eq 6
  end

  context 'when there are multiple batches' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'iterates the data correctly' do
      migrate!

      expect(queue.all.count).to eq 1
    end
  end
end
