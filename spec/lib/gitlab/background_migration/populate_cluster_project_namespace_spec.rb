# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateClusterProjectNamespace, :migration, schema: 20181009163424 do
  let(:migration) { described_class.new }
  let!(:cluster_projects) { create_list(:cluster_project, 10, namespace: nil) }

  subject { migration.perform(cluster_projects.min, cluster_projects.max) }

  it 'should update cluster project namespaces' do
    subject

    Clusters::Project.all.each do |cluster_project|
      expect(cluster_project.namespace).not_to be_nil
    end
  end
end
