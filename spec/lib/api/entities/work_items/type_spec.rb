# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Type, feature_category: :team_planning do
  let(:type) { build(:work_item_system_defined_type, :incident) }

  subject(:representation) do
    described_class.new(type).as_json
  end

  it 'exposes the type attributes' do
    expect(representation).to include(
      id: type.id,
      name: 'Incident',
      icon_name: 'work-item-incident'
    )
  end
end
