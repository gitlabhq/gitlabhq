# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddFunctionalIndexOnCiJobArtifactStatesForGeoBucket, feature_category: :geo_replication do
  let(:index_name) { described_class::INDEX_NAME }

  it 'creates the index' do
    migrate!

    connection = described_class.new.connection
    expect(connection.index_exists?(:ci_job_artifact_states, nil, name: index_name)).to be(true)
  end

  it 'removes the index on rollback' do
    migrate!
    schema_migrate_down!

    connection = described_class.new.connection
    expect(connection.index_exists?(:ci_job_artifact_states, nil, name: index_name)).to be(false)
  end
end
