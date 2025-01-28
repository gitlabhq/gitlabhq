# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  let_it_be(:current_user) { create(:user) }

  let_it_be(:project_a) { create(:project, name: 'A', star_count: 20) }
  let_it_be(:project_b) { create(:project, name: 'B', star_count: 10) }
  let_it_be(:project_c) { create(:project, name: 'C', description: 'B', star_count: 30) }

  let_it_be_with_reload(:resource_a) do
    create(:ci_catalog_resource, project: project_a, latest_released_at: '2023-02-01T00:00:00Z',
      last_30_day_usage_count: 150, verification_level: 100)
  end

  let_it_be(:resource_b) do
    create(:ci_catalog_resource, project: project_b, latest_released_at: '2023-01-01T00:00:00Z',
      last_30_day_usage_count: 100, verification_level: 10)
  end

  let_it_be(:resource_c) { create(:ci_catalog_resource, project: project_c, verification_level: 50) }

  it { is_expected.to belong_to(:project) }

  it do
    is_expected.to(
      have_many(:components).class_name('Ci::Catalog::Resources::Component').with_foreign_key(:catalog_resource_id))
  end

  it do
    is_expected.to(
      have_many(:component_usages).class_name('Ci::Catalog::Resources::Components::Usage')
        .with_foreign_key(:catalog_resource_id))
  end

  it do
    is_expected.to(
      have_many(:component_last_usages).class_name('Ci::Catalog::Resources::Components::LastUsage')
        .with_foreign_key(:catalog_resource_id))
  end

  it do
    is_expected.to(
      have_many(:versions).class_name('Ci::Catalog::Resources::Version').with_foreign_key(:catalog_resource_id))
  end

  it do
    is_expected.to(
      have_many(:sync_events).class_name('Ci::Catalog::Resources::SyncEvent').with_foreign_key(:catalog_resource_id))
  end

  it { is_expected.to delegate_method(:avatar_path).to(:project) }
  it { is_expected.to delegate_method(:star_count).to(:project) }

  it { is_expected.to define_enum_for(:state).with_values({ unpublished: 0, published: 1 }) }

  it 'defines verification levels matching the source of truth in VerifiedNamespace' do
    is_expected.to define_enum_for(:verification_level)
      .with_values(::Ci::Catalog::VerifiedNamespace::VERIFICATION_LEVELS)
  end

  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      resources_for_projects = described_class.for_projects(project_a.id)

      expect(resources_for_projects).to contain_exactly(resource_a)
    end
  end

  describe '.search' do
    it 'returns catalog resources whose name or description match the search term' do
      resources = described_class.search('B')

      expect(resources).to contain_exactly(resource_b, resource_c)
    end
  end

  describe '.order_by_created_at_desc' do
    it 'returns catalog resources sorted by descending created at' do
      ordered_resources = described_class.order_by_created_at_desc

      expect(ordered_resources.to_a).to eq([resource_c, resource_b, resource_a])
    end
  end

  describe '.order_by_created_at_asc' do
    it 'returns catalog resources sorted by ascending created at' do
      ordered_resources = described_class.order_by_created_at_asc

      expect(ordered_resources.to_a).to eq([resource_a, resource_b, resource_c])
    end
  end

  describe '.order_by_name_desc' do
    subject(:ordered_resources) { described_class.order_by_name_desc }

    it 'returns catalog resources sorted by descending name' do
      expect(ordered_resources.pluck(:name)).to eq(%w[C B A])
    end

    it 'returns catalog resources sorted by descending name with nulls last' do
      resource_a.update!(name: nil)

      expect(ordered_resources.pluck(:name)).to eq(['C', 'B', nil])
    end
  end

  describe '.order_by_name_asc' do
    subject(:ordered_resources) { described_class.order_by_name_asc }

    it 'returns catalog resources sorted by ascending name' do
      expect(ordered_resources.pluck(:name)).to eq(%w[A B C])
    end

    it 'returns catalog resources sorted by ascending name with nulls last' do
      resource_a.update!(name: nil)

      expect(ordered_resources.pluck(:name)).to eq(['B', 'C', nil])
    end
  end

  describe '.order_by_latest_released_at_desc' do
    it 'returns catalog resources sorted by latest_released_at descending with nulls last' do
      ordered_resources = described_class.order_by_latest_released_at_desc

      expect(ordered_resources).to eq([resource_a, resource_b, resource_c])
    end
  end

  describe '.order_by_latest_released_at_asc' do
    it 'returns catalog resources sorted by latest_released_at ascending with nulls last' do
      ordered_resources = described_class.order_by_latest_released_at_asc

      expect(ordered_resources).to eq([resource_b, resource_a, resource_c])
    end
  end

  describe 'order_by_star_count_desc' do
    it 'returns catalog resources sorted by project star count in descending order' do
      ordered_resources = described_class.order_by_star_count(:desc)

      expect(ordered_resources).to eq([resource_c, resource_a, resource_b])
    end
  end

  describe 'order_by_star_count_asc' do
    it 'returns catalog resources sorted by project star count in ascending order' do
      ordered_resources = described_class.order_by_star_count(:asc)

      expect(ordered_resources).to eq([resource_b, resource_a, resource_c])
    end
  end

  describe 'order_by_last_30_day_usage_count_desc' do
    it 'returns catalog resources sorted by last 30-day usage count in descending order' do
      ordered_resources = described_class.order_by_last_30_day_usage_count_desc

      expect(ordered_resources).to eq([resource_a, resource_b, resource_c])
    end
  end

  describe 'order_by_last_30_day_usage_count_asc' do
    it 'returns catalog resources sorted by last 30-day usage count in ascending order' do
      ordered_resources = described_class.order_by_last_30_day_usage_count_asc

      expect(ordered_resources).to eq([resource_c, resource_b, resource_a])
    end
  end

  describe '.for_verification_level' do
    it 'returns catalog resources for required verification_level' do
      verified_resources = described_class
        .for_verification_level(Ci::Catalog::VerifiedNamespace::VERIFICATION_LEVELS[:gitlab_maintained])

      expect(verified_resources).to eq([resource_a])
    end
  end

  describe 'authorized catalog resources' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:other_namespace) { create(:group) }
    let_it_be(:other_user) { create(:user) }

    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:internal_project) { create(:project, :internal) }
    let_it_be(:internal_namespace_project) { create(:project, :internal, namespace: namespace) }
    let_it_be(:private_namespace_project) { create(:project, namespace: namespace) }
    let_it_be(:other_private_namespace_project) { create(:project, namespace: other_namespace) }

    let_it_be(:public_resource) { create(:ci_catalog_resource, project: public_project) }
    let_it_be(:internal_resource) { create(:ci_catalog_resource, project: internal_project) }
    let_it_be(:internal_namespace_resource) { create(:ci_catalog_resource, project: internal_namespace_project) }
    let_it_be(:private_namespace_resource) { create(:ci_catalog_resource, project: private_namespace_project) }

    let_it_be(:other_private_namespace_resource) do
      create(:ci_catalog_resource, project: other_private_namespace_project)
    end

    before_all do
      namespace.add_reporter(current_user)
      other_namespace.add_guest(other_user)
    end

    describe '.public_or_visible_to_user' do
      subject(:resources) { described_class.public_or_visible_to_user(current_user) }

      it 'returns all resources visible to the user' do
        expect(resources).to contain_exactly(
          public_resource, internal_resource, internal_namespace_resource, private_namespace_resource)
      end

      context 'with a different user' do
        let(:current_user) { other_user }

        it 'returns all resources visible to the user' do
          expect(resources).to contain_exactly(
            public_resource, internal_resource, internal_namespace_resource, other_private_namespace_resource)
        end
      end

      context 'when the user is nil' do
        let(:current_user) { nil }

        it 'returns only public resources' do
          expect(resources).to contain_exactly(public_resource)
        end
      end
    end

    describe '.visible_to_user' do
      subject(:resources) { described_class.visible_to_user(current_user) }

      it "returns resources belonging to the user's authorized namespaces" do
        expect(resources).to contain_exactly(internal_namespace_resource, private_namespace_resource)
      end

      context 'with a different user' do
        let(:current_user) { other_user }

        it "returns resources belonging to the user's authorized namespaces" do
          expect(resources).to contain_exactly(other_private_namespace_resource)
        end
      end

      context 'when the user is nil' do
        let(:current_user) { nil }

        it 'does not return any resources' do
          expect(resources).to be_empty
        end
      end
    end
  end

  describe '#state' do
    it 'defaults to unpublished' do
      expect(resource_a.state).to eq('unpublished')
    end
  end

  describe '#publish!' do
    context 'when the catalog resource is in an unpublished state' do
      it 'updates the state of the catalog resource to published' do
        expect(resource_a.state).to eq('unpublished')

        resource_a.publish!

        expect(resource_a.reload.state).to eq('published')
      end
    end

    context 'when the catalog resource already has a published state' do
      it 'leaves the state as published' do
        resource_a.update!(state: :published)
        expect(resource_a.state).to eq('published')

        resource_a.publish!

        expect(resource_a.state).to eq('published')
      end
    end
  end

  describe 'synchronizing denormalized columns with `projects` table using SyncEvents processing', :sidekiq_inline do
    let_it_be_with_reload(:project) { create(:project, name: 'Test project', description: 'Test description') }

    context 'when the catalog resource is created' do
      let(:resource) { build(:ci_catalog_resource, project: project) }

      it 'updates the catalog resource columns to match the project' do
        resource.save!
        resource.reload

        expect(resource.name).to eq(project.name)
        expect(resource.description).to eq(project.description)
        expect(resource.visibility_level).to eq(project.visibility_level)
      end
    end

    context 'when the project is updated' do
      let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

      context 'when project name is updated' do
        it 'updates the catalog resource name to match' do
          project.update!(name: 'New name')

          expect(resource.reload.name).to eq(project.name)
        end
      end

      context 'when project description is updated' do
        it 'updates the catalog resource description to match' do
          project.update!(description: 'New description')

          expect(resource.reload.description).to eq(project.description)
        end
      end

      context 'when project visibility_level is updated' do
        it 'updates the catalog resource visibility_level to match' do
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)

          expect(resource.reload.visibility_level).to eq(project.visibility_level)
        end
      end
    end
  end

  describe 'updating latest_released_at using model callbacks' do
    let_it_be(:project) { create(:project) }
    let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

    let_it_be_with_refind(:january_release) do
      release = create(:release, :with_catalog_resource_version, project: project, tag: 'v1',
        released_at: '2023-01-01T00:00:00Z')

      release.catalog_resource_version.update!(semver: '1.0.0')

      release
    end

    let_it_be_with_refind(:february_release) do
      release = create(:release, :with_catalog_resource_version, project: project, tag: 'v2',
        released_at: '2023-02-01T00:00:00Z')

      release.catalog_resource_version.update!(semver: '2.0.0')

      release
    end

    it 'has the expected latest_released_at value' do
      expect(resource.reload.latest_released_at).to eq(february_release.released_at)
    end

    context 'when a new catalog resource version is created' do
      it 'updates the latest_released_at value' do
        march_release = create(:release, :with_catalog_resource_version, project: project, tag: 'v3',
          released_at: '2023-03-01T00:00:00Z')

        march_release.catalog_resource_version.update!(semver: '3.0.0')

        expect(resource.reload.latest_released_at).to eq(march_release.released_at)
      end
    end

    context 'when a catalog resource version is destroyed' do
      it 'updates the latest_released_at value' do
        february_release.catalog_resource_version.destroy!

        expect(resource.reload.latest_released_at).to eq(january_release.released_at)
      end
    end

    context 'when the released_at value of a release is updated' do
      it 'updates the latest_released_at value' do
        january_release.update!(released_at: '2024-03-01T00:00:00Z')

        january_release.catalog_resource_version.update!(semver: '4.0.0')

        expect(resource.reload.latest_released_at).to eq(january_release.released_at)
      end
    end

    context 'when a release is destroyed' do
      it 'updates the latest_released_at value' do
        february_release.destroy!
        expect(resource.reload.latest_released_at).to eq(january_release.released_at)
      end
    end

    context 'when all releases associated with the catalog resource are destroyed' do
      it 'updates the latest_released_at value to nil' do
        january_release.destroy!
        february_release.destroy!

        expect(resource.reload.latest_released_at).to be_nil
      end
    end
  end
end
