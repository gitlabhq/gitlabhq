# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItemDetail, feature_category: :team_planning do
  it 'uses Features::DetailEntity for feature serialization' do
    features_exposure = described_class.root_exposures.find { |e| e.key == :features }
    expect(features_exposure.using_class).to eq(API::Entities::WorkItems::Features::DetailEntity)
  end

  describe '#as_json' do
    let_it_be(:work_item) { create(:work_item) }

    context 'when requested_features is present' do
      subject(:representation) do
        described_class.new(work_item, requested_features: [:description]).as_json
      end

      it 'includes the features key' do
        expect(representation).to have_key(:features)
      end
    end

    context 'when requested_features is absent' do
      subject(:representation) { described_class.new(work_item).as_json }

      it 'omits the features key' do
        expect(representation).not_to have_key(:features)
      end
    end
  end
end
