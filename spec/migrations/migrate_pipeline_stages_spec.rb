require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170525132202_migrate_pipeline_stages.rb')

describe MigratePipelineStages, :migration, schema: 20170523091700 do
  ##
  # Create test data
  #
  before do
    table(:ci_pipelines).create!(ref: 'master', sha: 'adf43c3a')
  end

  it 'correctly migrates pipeline stages' do |migration, meta|
    expect(ActiveRecord::Base.connection.table_exists?('ci_stages')).to eq false

    migrate!

    expect(ActiveRecord::Base.connection.table_exists?('ci_stages')).to eq true
  end
end
