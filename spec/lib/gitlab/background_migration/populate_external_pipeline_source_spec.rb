# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateExternalPipelineSource, :migration, schema: 20180916011959 do
  let(:migration) { described_class.new }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:statuses) { table(:ci_builds) }
  let(:builds) { table(:ci_builds) }

  let!(:internal_pipeline) { pipelines.create(id: 1, source: described_class::Migratable::Pipeline.sources[:web]) }
  let!(:external_pipeline) { pipelines.create(id: 2, source: nil) }
  let!(:second_external_pipeline) { pipelines.create(id: 3, source: nil) }
  let!(:status) { statuses.create(id: 1, commit_id: 2, type: 'GenericCommitStatus') }
  let!(:build) { builds.create(id: 2, commit_id: 1, type: 'Ci::Build') }

  subject { migration.perform(1, 2) }

  it 'populates the pipeline source' do
    subject

    expect(external_pipeline.reload.source).to eq(described_class::Migratable::Pipeline.sources[:external])
  end

  it 'only processes a single batch of links at a time' do
    subject

    expect(second_external_pipeline.reload.source).to eq(nil)
  end

  it 'can be repeated without effect' do
    subject

    expect { subject }.not_to change { external_pipeline.reload.source }
  end
end
