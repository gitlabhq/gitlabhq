# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Permissions, feature_category: :team_planning do
  let(:current_user) { build(:user) }
  let(:work_item) { build(:work_item) }
  let(:allowed_abilities) { %i[read_work_item create_note clone_work_item] }
  let(:abilities_map) do
    described_class::PERMISSION_ABILITIES.index_with do |ability|
      allowed_abilities.include?(ability)
    end
  end

  subject(:representation) do
    described_class
      .new(work_item, current_user: current_user)
      .as_json
  end

  before do
    allow(Ability).to receive(:allowed?) do |user, ability, record|
      raise ArgumentError, 'unexpected user' unless user == current_user
      raise ArgumentError, 'unexpected record' unless record == work_item

      abilities_map.fetch(ability)
    end
  end

  it 'queries each permission ability with the current user and work item' do
    representation

    described_class::PERMISSION_ABILITIES.each do |ability|
      expect(Ability).to have_received(:allowed?).with(current_user, ability, work_item)
    end
  end

  it 'exposes boolean values for each permission' do
    expect(representation.keys).to match_array(described_class::PERMISSION_ABILITIES)

    described_class::PERMISSION_ABILITIES.each do |ability|
      expect(representation[ability]).to be(abilities_map[ability])
    end
  end
end
