# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignInternalIds, :migration, schema: 20201030203854 do
  subject { described_class.new(designs) }

  let_it_be(:namespaces)     { table(:namespaces) }
  let_it_be(:projects)       { table(:projects) }
  let_it_be(:designs)        { table(:design_management_designs) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:project_2) { projects.create!(namespace_id: namespace.id) }

  def create_design!(proj = project)
    designs.create!(project_id: proj.id, filename: generate(:filename))
  end

  def migrate!
    relation = designs.where(project_id: [project.id, project_2.id]).select(:project_id).distinct

    subject.perform(relation)
  end

  it 'backfills the iid for designs' do
    3.times { create_design! }

    expect do
      migrate!
    end.to change { designs.pluck(:iid) }.from(contain_exactly(nil, nil, nil)).to(contain_exactly(1, 2, 3))
  end

  it 'scopes IIDs and handles range and starting-point correctly' do
    create_design!.update!(iid: 10)
    create_design!.update!(iid: 12)
    create_design!(project_2).update!(iid: 7)
    project_3 = projects.create!(namespace_id: namespace.id)

    2.times { create_design! }
    2.times { create_design!(project_2) }
    2.times { create_design!(project_3) }

    migrate!

    expect(designs.where(project_id: project.id).pluck(:iid)).to contain_exactly(10, 12, 13, 14)
    expect(designs.where(project_id: project_2.id).pluck(:iid)).to contain_exactly(7, 8, 9)
    expect(designs.where(project_id: project_3.id).pluck(:iid)).to contain_exactly(nil, nil)
  end

  it 'updates the internal ID records' do
    design = create_design!
    2.times { create_design! }
    design.update!(iid: 10)
    scope = { project_id: project.id }
    usage = :design_management_designs
    init = ->(_d, _s) { 0 }

    ::InternalId.track_greatest(design, scope, usage, 10, init)

    migrate!

    next_iid = ::InternalId.generate_next(design, scope, usage, init)

    expect(designs.pluck(:iid)).to contain_exactly(10, 11, 12)
    expect(design.reload.iid).to eq(10)
    expect(next_iid).to eq(13)
  end
end
