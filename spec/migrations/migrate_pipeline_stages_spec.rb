require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170525132202_migrate_pipeline_stages.rb')

describe MigratePipelineStages, :migration, schema: 20170523091700 do
  def table(name)
    Class.new(ActiveRecord::Base) { self.table_name = name }
  end

  ##
  # Create test data
  #
  before do
    table(:ci_pipelines).create!(ref: 'master', sha: 'adf43c3a')
  end

  it 'correctly migrates pipeline stages' do
    expect(ActiveRecord::Base.connection.table_exists?('ci_stages')).to eq false

    described_class.new.migrate(:up)

    expect(ActiveRecord::Base.connection.table_exists?('ci_stages')).to eq true
  end
end
