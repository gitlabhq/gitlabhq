# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Resource do
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

  describe '.stale_processables' do
    subject { resource_group.resources.stale_processables }

    let!(:resource_group) { create(:ci_resource_group) }
    let!(:resource) { create(:ci_resource, processable: build, resource_group: resource_group) }

    context 'when the processable is running' do
      let!(:build) { create(:ci_build, :running, resource_group: resource_group) }

      before do
        # Creating unrelated builds to make sure the `retained` scope is working
        create(:ci_build, :running, resource_group: resource_group)
      end

      it 'returns empty' do
        is_expected.to be_empty
      end

      context 'and doomed' do
        before do
          build.doom!
        end

        it 'returns empty' do
          is_expected.to be_empty
        end

        it 'returns the stale prosessable a few minutes later' do
          travel_to(10.minutes.since) do
            is_expected.to eq([build])
          end
        end
      end
    end
  end
end
