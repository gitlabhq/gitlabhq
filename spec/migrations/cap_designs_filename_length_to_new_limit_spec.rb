# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CapDesignsFilenameLengthToNewLimit, :migration, schema: 20200528125905 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:designs) { table(:design_management_designs) }

  let(:filename_below_limit) { generate_filename(254) }
  let(:filename_at_limit) { generate_filename(255) }
  let(:filename_above_limit) { generate_filename(256) }

  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab', namespace_id: namespace.id) }
  let!(:issue) { issues.create!(description: 'issue', project_id: project.id) }

  def generate_filename(length, extension: '.png')
    name = 'a' * (length - extension.length)

    "#{name}#{extension}"
  end

  def create_design(filename)
    designs.create!(
      issue_id: issue.id,
      project_id: project.id,
      filename: filename
    )
  end

  it 'correctly sets filenames that are above the limit' do
    designs = [
      filename_below_limit,
      filename_at_limit,
      filename_above_limit
    ].map(&method(:create_design))

    migrate!

    designs.each(&:reload)

    expect(designs[0].filename).to eq(filename_below_limit)
    expect(designs[1].filename).to eq(filename_at_limit)
    expect(designs[2].filename).to eq([described_class::MODIFIED_NAME, designs[2].id, described_class::MODIFIED_EXTENSION].join)
  end

  it 'runs after filename limit has been set' do
    # This spec file uses the `schema:` keyword to run these tests
    # against a schema version before the one that sets the limit,
    # as otherwise we can't create the design data with filenames greater
    # than the limit.
    #
    # For this test, we migrate any skipped versions up to this migration.
    migration_context.migrate(20200602013901)

    create_design(filename_at_limit)
    expect { create_design(filename_above_limit) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
