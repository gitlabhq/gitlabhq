# frozen_string_literal: true

require 'spec_helper'

describe Ci::ResourceGroup do
  describe 'validation' do
    it 'valids when key includes allowed character' do
      resource_group = build(:ci_resource_group, key: 'test')

      expect(resource_group).to be_valid
    end

    it 'invalids when key includes invalid character' do
      resource_group = build(:ci_resource_group, key: ':::')

      expect(resource_group).not_to be_valid
    end
  end

  describe '#ensure_resource' do
    it 'creates one resource when resource group is created' do
      resource_group = create(:ci_resource_group)

      expect(resource_group.resources.count).to eq(1)
      expect(resource_group.resources.all?(&:persisted?)).to eq(true)
    end
  end

  describe '#retain_resource_for' do
    subject { resource_group.retain_resource_for(build) }

    let(:build) { create(:ci_build) }
    let(:resource_group) { create(:ci_resource_group) }

    it 'retains resource for the build' do
      expect(resource_group.resources.first.build).to be_nil

      is_expected.to eq(true)

      expect(resource_group.resources.first.build).to eq(build)
    end

    context 'when there are no free resources' do
      before do
        resource_group.retain_resource_for(create(:ci_build))
      end

      it 'fails to retain resource' do
        is_expected.to eq(false)
      end
    end

    context 'when the build has already retained a resource' do
      let!(:another_resource) { create(:ci_resource, resource_group: resource_group, build: build) }

      it 'fails to retain resource' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe '#release_resource_from' do
    subject { resource_group.release_resource_from(build) }

    let(:build) { create(:ci_build) }
    let(:resource_group) { create(:ci_resource_group) }

    context 'when the build has already retained a resource' do
      before do
        resource_group.retain_resource_for(build)
      end

      it 'releases resource from the build' do
        expect(resource_group.resources.first.build).to eq(build)

        is_expected.to eq(true)

        expect(resource_group.resources.first.build).to be_nil
      end
    end

    context 'when the build has already released a resource' do
      it 'fails to release resource' do
        is_expected.to eq(false)
      end
    end
  end
end
