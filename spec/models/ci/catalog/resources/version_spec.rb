# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Version, type: :model, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  include_context 'when there are catalog resources with versions'

  it { is_expected.to belong_to(:release) }
  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:components).class_name('Ci::Catalog::Resources::Component') }

  it { is_expected.to delegate_method(:sha).to(:release) }
  it { is_expected.to delegate_method(:author_id).to(:release) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:release) }
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:project) }

    describe 'semver validation' do
      where(:version, :valid, :semver_major, :semver_minor, :semver_patch, :semver_prerelease) do
        '1'             | false | nil | nil | nil | nil
        '1.2'           | false | nil | nil | nil | nil
        '1.2.3'         | true  | 1   | 2   | 3   | nil
        '1.2.3-beta'    | true  | 1   | 2   | 3   | 'beta'
        '1.2.3.beta'    | false | nil | nil | nil | nil
      end

      with_them do
        let(:catalog_version) { build(:ci_catalog_resource_version, version: version) }

        it do
          expect(catalog_version.semver_major).to be semver_major
          expect(catalog_version.semver_minor).to be semver_minor
          expect(catalog_version.semver_patch).to be semver_patch
          expect(catalog_version.semver_prerelease).to eq semver_prerelease
        end
      end
    end
  end

  describe '.for_catalog resources' do
    it 'returns versions for the given catalog resources' do
      versions = described_class.for_catalog_resources([resource1, resource2])

      expect(versions).to match_array([v1_0, v1_1, v2_0, v2_1])
    end
  end

  describe '.by_name' do
    it 'returns the version that matches the name' do
      versions = described_class.by_name('1.0.0')

      expect(versions.count).to eq(1)
      expect(versions.first.name).to eq('1.0.0')
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
        v1_0.release.update_column(:sha, nil)

        is_expected.to be_nil
      end
    end
  end

  describe '#readme' do
    it 'returns the correct readme for the version' do
      expect(v1_0.readme.data).to include('Readme 1.0.0')
      expect(v1_1.readme.data).to include('Readme 1.1.0')
    end
  end

  describe 'synchronizing released_at with `releases` table using model callbacks' do
    let_it_be(:project) { create(:project) }
    let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

    let_it_be_with_reload(:release) do
      create(:release, :with_catalog_resource_version, project: project, tag: 'v1', released_at: '2023-01-01T00:00:00Z')
    end

    let(:version) { release.catalog_resource_version }

    context 'when the version is created' do
      it 'updates released_at to match the release' do
        expect(version.read_attribute(:released_at)).to eq(release.released_at)
      end
    end

    context 'when release.released_at is updated' do
      it 'updates released_at to match the release' do
        release.update!(released_at: '2023-02-02T00:00:00Z')

        expect(version.read_attribute(:released_at)).to eq(release.released_at)
      end
    end
  end
end
