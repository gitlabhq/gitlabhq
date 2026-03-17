# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Labels, feature_category: :team_planning do
  let(:label) { build(:label, title: 'bug', color: '#FF0000') }
  let(:labels_widget) do
    instance_double(
      WorkItems::Widgets::Labels,
      allows_scoped_labels?: true,
      labels: [label]
    )
  end

  let(:options) { {} }

  subject(:representation) do
    described_class.new(labels_widget, options).as_json
  end

  it 'exposes whether scoped labels are allowed' do
    expect(representation[:allows_scoped_labels]).to be(true)
  end

  it 'represents labels using the work item label entity' do
    expected_label = API::Entities::WorkItems::Label
      .new(label)
      .as_json

    expect(representation[:labels]).to contain_exactly(expected_label)
  end

  context 'when resource_parent option is provided' do
    let(:resource_parent) { instance_double(Group) }
    let(:options) { { resource_parent: resource_parent } }

    it 'uses resource_parent to check scoped labels instead of the widget' do
      allow(resource_parent).to receive(:licensed_feature_available?).with(:scoped_labels).and_return(false)

      expect(labels_widget).not_to receive(:allows_scoped_labels?)
      expect(resource_parent).to receive(:licensed_feature_available?).with(:scoped_labels)

      expect(representation[:allows_scoped_labels]).to be(false)
    end

    it 'returns true when scoped_labels license is available' do
      allow(resource_parent).to receive(:licensed_feature_available?).with(:scoped_labels).and_return(true)

      expect(representation[:allows_scoped_labels]).to be(true)
    end

    it 'returns false when scoped_labels license is not available' do
      allow(resource_parent).to receive(:licensed_feature_available?).with(:scoped_labels).and_return(false)

      expect(representation[:allows_scoped_labels]).to be(false)
    end
  end

  context 'when resource_parent option is not provided' do
    it 'uses the widget to check scoped labels' do
      expect(labels_widget).to receive(:allows_scoped_labels?)

      representation
    end
  end
end
