# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180725011345_null_out_clusters_applications_prometheus_version.rb')

describe NullOutClustersApplicationsPrometheusVersion, :migration do
  let(:applications) { table(:clusters_applications_prometheus) }
  let(:clusters) { table(:clusters) }

  before do
    cluster = clusters.create!(id: 123, name: 'hello')
    applications.create!(id: 123, status: 'installed', version: '2.0.0', cluster_id: cluster.id)
    applications.create!(id: 124, status: 'installed', version: '6.7.3', cluster_id: cluster.id)
  end

  it 'nulls out the version column' do
    expect(applications.count).to eq 2

    migrate!

    expect(applications.pluck(:version)).to match_array [nil, '6.7.3']
  end
end
