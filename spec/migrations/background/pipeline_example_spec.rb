require 'spec_helper'

describe Migration::PipelineExample do
  ##
  # We need to maintain this migration until we decide to drop backward
  # compatibility. We soon won't be able to use factories to create records
  # using the old database schema.
  #
  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'ci_pipelines'
    end
  end

  ##
  # Set initial database state using raw model.
  #
  let!(:pipeline) do
    model.create!(status: 'running', duration: 0, sha: 12345, ref: 'master')
  end

  it 'migrates data' do
    expect(Ci::Pipeline.count).to eq 1 # sanity check 01

    described_class.perform(pipeline.id, 54321, Ci::Pipeline)

    expect(pipeline.reload.status).to eq 'success'
    expect(pipeline.reload.duration).to eq 1234
    expect(pipeline.reload.schema_version).to eq 54321 # sanity check 02
    expect(Ci::Pipeline.find(pipeline.id)).to be_valid # sanity check 03
  end
end
