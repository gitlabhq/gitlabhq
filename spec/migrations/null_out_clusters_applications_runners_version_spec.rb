# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180725010623_null_out_clusters_applications_runners_version.rb')

describe NullOutClustersApplicationsRunnersVersion, :migration do
  let(:applications) { table(:clusters_applications_runners) }
  let(:clusters) { table(:clusters) }

  before do
    cluster = clusters.create!(id: 123, name: 'hello')
    applications.create!(id: 123, status: 'installed', version: '0.1.13', cluster_id: cluster.id)
  end

  it 'nulls out the version column' do
    migrate!

    expect(applications.first.version).to be_nil
  end
end
