# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Resource, feature_category: :continuous_delivery do
  describe '.free' do
    subject { described_class.free }

    let(:resource_group) { create(:ci_resource_group) }
    let!(:free_resource) { resource_group.resources.take }
    let!(:retained_resource) { create(:ci_resource, :retained, resource_group: resource_group) }

    it 'returns free resources' do
      is_expected.to eq([free_resource])
    end
  end

  describe '.retained' do
    subject { described_class.retained }

    it "returns the resource if it's retained" do
      resource = create(:ci_resource, processable: create(:ci_build))

      is_expected.to eq([resource])
    end

    it "returns empty if it's not retained" do
      create(:ci_resource, processable: nil)

      is_expected.to be_empty
    end
  end

  describe '.retained_by' do
    subject { described_class.retained_by(build) }

    let(:build) { create(:ci_build) }
    let!(:resource) { create(:ci_resource, processable: build) }

    it 'returns retained resources' do
      is_expected.to eq([resource])
    end
  end
end
