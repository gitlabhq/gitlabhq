# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Version, type: :model, feature_category: :pipeline_composition do
  include_context 'when there are catalog resources with versions'

  it { is_expected.to belong_to(:release) }
  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:components).class_name('Ci::Catalog::Resources::Component') }

  it { is_expected.to delegate_method(:sha).to(:release) }
  it { is_expected.to delegate_method(:released_at).to(:release) }
  it { is_expected.to delegate_method(:author_id).to(:release) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:release) }
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '.for_catalog resources' do
    it 'returns versions for the given catalog resources' do
      versions = described_class.for_catalog_resources([resource1, resource2])

      expect(versions).to match_array([v1_0, v1_1, v2_0, v2_1])
    end
  end

  describe '.by_name' do
    it 'returns the version that matches the name' do
      versions = described_class.by_name('v1.0')

      expect(versions.count).to eq(1)
      expect(versions.first.name).to eq('v1.0')
    end

    context 'when no version matches the name' do
      it 'returns empty response' do
        versions = described_class.by_name('does_not_exist')

        expect(versions).to be_empty
      end
    end
  end

  describe '.order_by_created_at_asc' do
    it 'returns versions ordered by created_at ascending' do
      versions = described_class.order_by_created_at_asc

      expect(versions).to eq([v2_1, v2_0, v1_1, v1_0])
    end
  end

  describe '.order_by_created_at_desc' do
    it 'returns versions ordered by created_at descending' do
      versions = described_class.order_by_created_at_desc

      expect(versions).to eq([v1_0, v1_1, v2_0, v2_1])
    end
  end

  describe '.order_by_released_at_asc' do
    it 'returns versions ordered by released_at ascending' do
      versions = described_class.order_by_released_at_asc

      expect(versions).to eq([v1_0, v1_1, v2_0, v2_1])
    end
  end

  describe '.order_by_released_at_desc' do
    it 'returns versions ordered by released_at descending' do
      versions = described_class.order_by_released_at_desc

      expect(versions).to eq([v2_1, v2_0, v1_1, v1_0])
    end
  end

  describe '.latest' do
    subject { described_class.latest }

    it 'returns the latest version by released date' do
      is_expected.to eq(v2_1)
    end

    context 'when there are no versions' do
      it 'returns nil' do
        resource1.versions.delete_all(:delete_all)
        resource2.versions.delete_all(:delete_all)

        is_expected.to be_nil
      end
    end
  end

  describe '.latest_for_catalog resources' do
    subject { described_class.latest_for_catalog_resources([resource1, resource2]) }

    it 'returns the latest version for each catalog resource' do
      is_expected.to match_array([v1_1, v2_1])
    end

    context 'when one catalog resource does not have versions' do
      it 'returns the latest version of only the catalog resource with versions' do
        resource1.versions.delete_all(:delete_all)

        is_expected.to match_array([v2_1])
      end
    end

    context 'when no catalog resource has versions' do
      it 'returns empty response' do
        resource1.versions.delete_all(:delete_all)
        resource2.versions.delete_all(:delete_all)

        is_expected.to be_empty
      end
    end
  end

  describe '#update_catalog_resource' do
    let_it_be(:release) { create(:release, project: project1, tag: 'v1') }
    let(:version) { build(:ci_catalog_resource_version, catalog_resource: resource1, release: release) }

    context 'when a version is created' do
      it 'calls update_catalog_resource' do
        expect(version).to receive(:update_catalog_resource).once

        version.save!
      end
    end

    context 'when a version is destroyed' do
      it 'calls update_catalog_resource' do
        version.save!

        expect(version).to receive(:update_catalog_resource).once

        version.destroy!
      end
    end
  end

  describe '#name' do
    it 'is equivalent to release.tag' do
      v1_0.release.update!(name: 'Release v1.0')

      expect(v1_0.name).to eq(v1_0.release.tag)
    end
  end

  describe '#commit' do
    subject(:commit) { v1_0.commit }

    it 'returns a commit' do
      is_expected.to be_a(Commit)
    end

    context 'when the sha is nil' do
      it 'returns nil' do
        v1_0.release.update!(sha: nil)

        is_expected.to be_nil
      end
    end
  end

  describe '#readme' do
    it 'returns the correct readme for the version' do
      expect(v1_0.readme.data).to include('Readme v1.0')
      expect(v1_1.readme.data).to include('Readme v1.1')
    end
  end
end
