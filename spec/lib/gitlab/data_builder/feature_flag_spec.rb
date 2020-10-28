# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::FeatureFlag do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:feature_flag) { create(:operations_feature_flag, project: project) }

  describe '.build' do
    let(:data) { described_class.build(feature_flag, user) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:object_kind]).to eq('feature_flag') }

    it 'contains the correct object attributes' do
      object_attributes = data[:object_attributes]

      expect(object_attributes[:id]).to eq(feature_flag.id)
      expect(object_attributes[:name]).to eq(feature_flag.name)
      expect(object_attributes[:description]).to eq(feature_flag.description)
      expect(object_attributes[:active]).to eq(feature_flag.active)
    end
  end
end
