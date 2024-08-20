# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Version, type: :model, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:minor_release) { create(:release, project: project, tag: '1.1.0', created_at: Date.yesterday - 1.day) }
  let_it_be(:major_release) { create(:release, project: project, tag: '2.0.0', created_at: Date.yesterday) }
  let_it_be(:patch) { create(:release, project: project, tag: 'v1.1.3', created_at: Date.today, sha: 'patch_sha') }
  let!(:v1_1_0) do
    create(:ci_catalog_resource_version, semver: '1.1.0', catalog_resource: resource, release: minor_release)
  end

  let!(:v1_1_3) { create(:ci_catalog_resource_version, semver: 'v1.1.3', catalog_resource: resource, release: patch) }
  let!(:v2_0_0) do
    create(:ci_catalog_resource_version, semver: '2.0.0', catalog_resource: resource, release: major_release)
  end

  subject(:version) { v1_1_0 }

  it { is_expected.to belong_to(:release) }
  it { is_expected.to belong_to(:catalog_resource).class_name('Ci::Catalog::Resource') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:published_by).class_name('User') }
  it { is_expected.to have_many(:components).class_name('Ci::Catalog::Resources::Component') }
  it { is_expected.to delegate_method(:sha).to(:release) }
  it { is_expected.to delegate_method(:author_id).to(:release) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:release) }
    it { is_expected.to validate_presence_of(:catalog_resource) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:published_by).on(:create) }

    describe 'semver validation' do
      where(:version, :valid, :semver_major, :semver_minor, :semver_patch, :semver_prerelease) do
        '1'          | false | nil | nil | nil | nil
        '1.2'        | false | nil | nil | nil | nil
        '1.2.3'      | true  | 1   | 2   | 3   | nil
        'v1.2.3'     | true  | 1   | 2   | 3   | nil
        'V1.2.3'     | false | nil | nil | nil | nil
        '1.2.3-beta' | true  | 1   | 2   | 3   | 'beta'
        '1.2.3.beta' | true  | nil | nil | nil | nil
      end

      with_them do
        let(:catalog_version) { build(:ci_catalog_resource_version, semver: version) }

        it do
          expect(catalog_version.semver_major).to be semver_major
          expect(catalog_version.semver_minor).to be semver_minor
          expect(catalog_version.semver_patch).to be semver_patch
          expect(catalog_version.semver_prerelease).to eq semver_prerelease
        end
      end
    end

    describe 'validate_published_by_is_release_author' do
      it 'validates that the published_by user is the release author' do
        version = build(:ci_catalog_resource_version, release: major_release, published_by: current_user)

        expect(version).to be_invalid
        expect(version.errors.full_messages).to include('Published by must be the same as the release author')
      end
    end
  end

  describe 'with multiple catalog resources' do
    let_it_be(:project2) { create(:project, :catalog_resource_with_components) }
    let_it_be(:resource2) { create(:ci_catalog_resource, project: project2) }
    let_it_be(:release_v3) { create(:release, tag: '3.0.0', project: project2, created_at: Date.yesterday) }
    let_it_be(:v3_0_0) do
      create(:ci_catalog_resource_version, catalog_resource: resource2, semver: '3.0.0', release: release_v3)
    end

    describe '.for_catalog resources' do
      it 'returns versions for the given catalog resources' do
        versions = described_class.for_catalog_resources([resource, resource2])

        expect(versions).to match_array([v1_1_3, v2_0_0, v1_1_0, v3_0_0])
      end
    end

    describe '.versions_for_catalog_resources' do
      subject { described_class.versions_for_catalog_resources([resource, resource2]) }

      it 'returns versions for each catalog resource ordered by semantic version' do
        is_expected.to match_array([v3_0_0, v2_0_0, v1_1_3, v1_1_0])
      end
    end
  end

  describe '.with_semver' do
    subject { described_class.with_semver }

    it 'excludes non semver versions' do
      v1_1_3.semver_major = nil
      v1_1_3.save!(validate: false)

      is_expected.to match_array([v2_0_0, v1_1_0])
    end
  end

  describe '.without_prerelease' do
    subject { described_class.without_prerelease }

    it 'excludes pre-releases' do
      beta_release = create(:release, project: project, tag: '3.1.3-beta')
      create(:ci_catalog_resource_version, semver: '3.1.3-beta', catalog_resource: resource,
        release: beta_release)

      is_expected.to match_array([v2_0_0, v1_1_0, v1_1_3])
    end
  end

  describe '.latest' do
    context 'when providing the ~latest tag' do
      it 'returns the latest version' do
        latest_version = described_class.latest

        expect(latest_version).to eq(v2_0_0)
      end

      it 'excludes pre-release versions' do
        beta_release = create(:release, project: project, tag: '3.1.3-beta', created_at: Date.today)
        create(:ci_catalog_resource_version, semver: '3.1.3-beta', catalog_resource: resource,
          release: beta_release)

        latest_version = described_class.latest

        expect(latest_version).to eq(v2_0_0)
      end
    end

    context 'when providing only a major version number' do
      it 'returns the latest for the given major version' do
        latest_major_version = described_class.latest('1')

        expect(latest_major_version).to eq(v1_1_3)
      end
    end

    context 'when providing a major and minor version number' do
      it 'returns the latest for the given minor version' do
        latest_minor_version = described_class.latest('1', '1')

        expect(latest_minor_version).to eq(v1_1_3)
      end
    end

    context 'when providing only a minor version but no major version' do
      it 'raises an error' do
        expect { described_class.latest(nil, '1') }
        .to raise_error(ArgumentError, 'semver minor version used without major version')
      end
    end
  end

  describe '.by_name' do
    it 'returns the version that matches the name' do
      versions = described_class.by_name('1.1.0')

      expect(versions.count).to eq(1)
      expect(versions.first.name).to eq('1.1.0')
    end
  end

  describe '.by_sha' do
    it 'returns the version that matches the sha' do
      versions = described_class.by_sha('patch_sha')

      expect(versions.count).to eq(1)
      expect(versions.first.sha).to eq('patch_sha')
    end
  end

  describe '#name' do
    it 'is equivalent to semver' do
      expect(v1_1_0.name).to eq(v1_1_0.semver.to_s)
    end
  end

  describe '#commit' do
    subject(:commit) { v1_1_0.commit }

    it 'returns a commit' do
      is_expected.to be_a(Commit)
    end
  end

  describe '#readme' do
    before_all do
      project.repository.create_branch('patch_v1_1_2', project.default_branch)
      project.repository.create_file(
        current_user, 'README.md', 'Patch v1.2.3', message: 'Update', branch_name: 'patch_v1_2_3')
      project.repository.add_tag(current_user, '1.2.3', 'patch_v1_2_3')
    end

    it 'returns the correct readme for the version' do
      v1_2_3 = create(:release, :with_catalog_resource_version, project: project, tag: '1.2.3',
        sha: project.commit('1.2.3').sha)

      expect(v1_1_0.readme).to include('testme')
      expect(v1_2_3.catalog_resource_version.readme).to include('Patch v1.2.3')
    end
  end

  describe 'synchronizing released_at with `releases` table using model callbacks' do
    let_it_be(:project) { create(:project, :repository) }
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
