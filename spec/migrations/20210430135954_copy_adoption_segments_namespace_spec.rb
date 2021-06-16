# frozen_string_literal: true

require 'spec_helper'

require_migration!('copy_adoption_segments_namespace')

RSpec.describe CopyAdoptionSegmentsNamespace, :migration do
  let(:namespaces_table) { table(:namespaces) }
  let(:segments_table) { table(:analytics_devops_adoption_segments) }

  before do
    namespaces_table.create!(id: 123, name: 'group1', path: 'group1')
    namespaces_table.create!(id: 124, name: 'group2', path: 'group2')

    segments_table.create!(id: 1, namespace_id: 123, display_namespace_id: nil)
    segments_table.create!(id: 2, namespace_id: 124, display_namespace_id: 123)
  end

  it 'updates all segments without display namespace' do
    migrate!

    expect(segments_table.find(1).display_namespace_id).to eq 123
    expect(segments_table.find(2).display_namespace_id).to eq 123
  end
end
