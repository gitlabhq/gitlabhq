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

  subject(:representation) do
    described_class.new(labels_widget).as_json
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
end
