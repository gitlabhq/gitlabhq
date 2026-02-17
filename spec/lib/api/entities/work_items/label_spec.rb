# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Label, feature_category: :team_planning do
  let(:label) { build_stubbed(:label, title: 'bug', description: 'Bug reports', color: '#FF8800') }

  subject(:representation) do
    described_class.new(label).as_json
  end

  it 'exposes the label attributes' do
    expect(representation).to include(
      id: label.id,
      title: 'bug',
      description: 'Bug reports',
      color: '#FF8800',
      text_color: label.text_color
    )
  end
end
