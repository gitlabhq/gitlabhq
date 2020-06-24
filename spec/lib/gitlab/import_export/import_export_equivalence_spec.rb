# frozen_string_literal: true

require 'spec_helper'

# Verifies that given an exported project meta-data tree, when importing this
# tree and then exporting it again, we should obtain the initial tree.
#
# This equivalence only works up to a certain extent, for instance we need
# to ignore:
#
# - row IDs and foreign key IDs
# - some timestamps
# - randomly generated fields like tokens
#
# as these are expected to change between import/export cycles.
RSpec.describe Gitlab::ImportExport do
  include ImportExport::CommonUtil
  include ConfigurationHelper
  include ImportExport::ProjectTreeExpectations

  let(:json_fixture) { 'complex' }

  before do
    stub_feature_flags(project_export_as_ndjson: false)
  end

  it 'yields the initial tree when importing and exporting it again' do
    project = create(:project, creator: create(:user, :admin))

    # We first generate a test fixture dynamically from a seed-fixture, so as to
    # account for any fields in the initial fixture that are missing and set to
    # defaults during import (ideally we should have realistic test fixtures
    # that "honestly" represent exports)
    expect(
      restore_then_save_project(
        project,
        import_path: seed_fixture_path,
        export_path: test_fixture_path)
    ).to be true
    # Import, then export again from the generated fixture. Any residual changes
    # in the JSON will count towards comparison i.e. test failures.
    expect(
      restore_then_save_project(
        project,
        import_path: test_fixture_path,
        export_path: test_tmp_path)
    ).to be true

    imported_json = Gitlab::Json.parse(File.read("#{test_fixture_path}/project.json"))
    exported_json = Gitlab::Json.parse(File.read("#{test_tmp_path}/project.json"))

    assert_relations_match(imported_json, exported_json)
  end

  private

  def seed_fixture_path
    "#{fixtures_path}/#{json_fixture}"
  end

  def test_fixture_path
    "#{test_tmp_path}/#{json_fixture}"
  end
end
