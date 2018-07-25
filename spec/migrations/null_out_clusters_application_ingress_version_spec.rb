# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180725004652_null_out_clusters_application_ingress_version.rb')

describe NullOutClustersApplicationIngressVersion, :migration do
  let(:applications) { table(:clusters_applications_ingress) }
  let(:clusters) { table(:clusters) }

  before do
    cluster = clusters.create!(id: 123, name: 'hello')
    applications.create!(id: 123, status: 'installed', ingress_type: 1, version: 'nginx', cluster_id: cluster.id)
  end

  it 'nulls out the version column' do
    migrate!

    expect(applications.first.version).to be_nil
  end
end
