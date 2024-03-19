# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Listing, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:public_namespace_project) do
    create(:project, :public, namespace: namespace, name: 'A public namespace project', star_count: 10)
  end

  let_it_be(:public_project) do
    create(:project, :public, name: 'B public test project', star_count: 20)
  end

  let_it_be(:namespace_project_a) do
    create(:project, namespace: namespace, name: 'Test namespace project', star_count: 30)
  end

  let_it_be(:namespace_project_b) do
    create(:project, namespace: namespace, name: 'X namespace Project', star_count: 40)
  end

  let_it_be(:project_noaccess) { create(:project, namespace: namespace, name: 'Project with no access') }
  let_it_be(:internal_project) { create(:project, :internal, name: 'Internal project') }

  let_it_be(:private_project) do
    create(:project, namespace: namespace, name: 'B Project', description: 'Rspec test framework')
  end

  let(:list) { described_class.new(user) }

  before_all do
    namespace_project_a.add_reporter(user)
    namespace_project_b.add_reporter(user)
    public_namespace_project.add_reporter(user)
    public_project.add_reporter(user)
    internal_project.add_owner(user)
  end

  describe '#resources' do
    subject(:resources) { list.resources(**params) }

    let(:params) { {} }

    let_it_be(:public_resource_a) { create(:ci_catalog_resource, :published, project: public_namespace_project) }
    let_it_be(:public_resource_b) { create(:ci_catalog_resource, :published, project: public_project) }
    let_it_be(:internal_resource) { create(:ci_catalog_resource, :published, project: internal_project) }
    let_it_be(:private_namespace_resource) { create(:ci_catalog_resource, :published, project: namespace_project_a) }
    let_it_be(:unpublished_resource) { create(:ci_catalog_resource, project: namespace_project_b) }

    it 'by default returns all resources visible to the current user' do
      is_expected.to contain_exactly(public_resource_a, public_resource_b, private_namespace_resource,
        internal_resource)
    end

    context 'when user is anonymous' do
      let(:user) { nil }

      it 'returns only published resources for public projects' do
        is_expected.to contain_exactly(public_resource_a, public_resource_b)
      end
    end

    context 'when search params are provided' do
      let(:params) { { search: 'test' } }

      it 'returns the resources that match the search params' do
        is_expected.to contain_exactly(public_resource_b, private_namespace_resource)
      end

      context 'when search term is too small' do
        let(:params) { { search: 'te' } }

        it { is_expected.to be_empty }
      end
    end

    context 'when the scope is :namespaces' do
      let_it_be(:public_resource_no_namespace) do
        create(:ci_catalog_resource, project: create(:project, :public, name: 'public'))
      end

      let(:params) { { scope: :namespaces } }

      it "returns the catalog resources belonging to the user's authorized namespaces" do
        is_expected.to contain_exactly(public_resource_a, public_resource_b, internal_resource,
          private_namespace_resource)
      end
    end

    context 'with a sort parameter' do
      let_it_be(:today) { Time.zone.now }
      let_it_be(:yesterday) { today - 1.day }
      let_it_be(:tomorrow) { today + 1.day }

      let(:params) { { sort: sort } }

      before_all do
        public_resource_a.update!(created_at: today, latest_released_at: yesterday)
        public_resource_b.update!(created_at: yesterday, latest_released_at: today)
        private_namespace_resource.update!(created_at: tomorrow, latest_released_at: tomorrow)
        internal_resource.update!(created_at: tomorrow + 1)
      end

      context 'when there is no sort parameter' do
        let_it_be(:sort) { nil }

        it 'contains catalog resources sorted by star_count descending' do
          is_expected.to eq([private_namespace_resource, public_resource_b, public_resource_a, internal_resource])
        end
      end

      context 'when the sort is created_at ascending' do
        let_it_be(:sort) { :created_at_asc }

        it 'contains catalog resources sorted by created_at ascending' do
          is_expected.to eq([public_resource_b, public_resource_a, private_namespace_resource, internal_resource])
        end
      end

      context 'when the sort is created_at descending' do
        let_it_be(:sort) { :created_at_desc }

        it 'contains catalog resources sorted by created_at descending' do
          is_expected.to eq([internal_resource, private_namespace_resource, public_resource_a, public_resource_b])
        end
      end

      context 'when the sort is name ascending' do
        let_it_be(:sort) { :name_asc }

        it 'contains catalog resources for projects sorted by name ascending' do
          is_expected.to eq([public_resource_a, public_resource_b, internal_resource, private_namespace_resource])
        end
      end

      context 'when the sort is name descending' do
        let_it_be(:sort) { :name_desc }

        it 'contains catalog resources for projects sorted by name descending' do
          is_expected.to eq([private_namespace_resource, internal_resource, public_resource_b, public_resource_a])
        end
      end

      context 'when the sort is latest_released_at ascending' do
        let_it_be(:sort) { :latest_released_at_asc }

        it 'contains catalog resources sorted by latest_released_at ascending with nulls last' do
          is_expected.to eq([public_resource_a, public_resource_b, private_namespace_resource, internal_resource])
        end
      end

      context 'when the sort is latest_released_at descending' do
        let_it_be(:sort) { :latest_released_at_desc }

        it 'contains catalog resources sorted by latest_released_at descending with nulls last' do
          is_expected.to eq([private_namespace_resource, public_resource_b, public_resource_a, internal_resource])
        end
      end

      context 'when the sort is star_count ascending' do
        let_it_be(:sort) { :star_count_asc }

        it 'contains catalog resource sorted by star_count ascending' do
          is_expected.to eq([internal_resource, public_resource_a, public_resource_b, private_namespace_resource])
        end
      end
    end
  end

  describe '#find_resource' do
    let_it_be(:accessible_resource) { create(:ci_catalog_resource, :published, project: public_project) }
    let_it_be(:inaccessible_resource) { create(:ci_catalog_resource, :published, project: project_noaccess) }
    let_it_be(:unpublished_resource) do
      create(:ci_catalog_resource, project: public_namespace_project, state: :unpublished)
    end

    context 'when using the ID argument' do
      subject { list.find_resource(id: id) }

      context 'when the resource is published and visible to the user' do
        let(:id) { accessible_resource.id }

        it 'fetches the resource' do
          is_expected.to eq(accessible_resource)
        end
      end

      context 'when the resource is not found' do
        let(:id) { 'not-an-id' }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'when the resource is not published' do
        let(:id) { unpublished_resource.id }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context "when the current user cannot read code on the resource's project" do
        let(:id) { inaccessible_resource.id }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end

    context 'when using the full_path argument' do
      subject { list.find_resource(full_path: full_path) }

      context 'when the resource is published and visible to the user' do
        let(:full_path) { accessible_resource.project.full_path }

        it 'fetches the resource' do
          is_expected.to eq(accessible_resource)
        end
      end

      context 'when the resource is not found' do
        let(:full_path) { 'not-a-path' }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'when the resource is not published' do
        let(:full_path) { unpublished_resource.project.full_path }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context "when the current user cannot read code on the resource's project" do
        let(:full_path) { inaccessible_resource.project.full_path }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end
end
