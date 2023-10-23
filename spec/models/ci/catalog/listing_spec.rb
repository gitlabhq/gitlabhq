# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Listing, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project_x)        { create(:project, namespace: namespace, name: 'X Project') }
  let_it_be(:project_a)        { create(:project, :public, namespace: namespace, name: 'A Project') }
  let_it_be(:project_noaccess) { create(:project, namespace: namespace, name: 'C Project') }
  let_it_be(:project_ext)      { create(:project, :public, name: 'TestProject') }
  let_it_be(:user) { create(:user) }

  let_it_be(:project_b) do
    create(:project, namespace: namespace, name: 'B Project', description: 'Rspec test framework')
  end

  let(:list) { described_class.new(user) }

  before_all do
    project_x.add_reporter(user)
    project_b.add_reporter(user)
    project_a.add_reporter(user)
    project_ext.add_reporter(user)
  end

  describe '#resources' do
    subject(:resources) { list.resources(**params) }

    context 'when user is anonymous' do
      let(:user) { nil }
      let(:params) { {} }

      let!(:resource_1) { create(:ci_catalog_resource, project: project_a) }
      let!(:resource_2) { create(:ci_catalog_resource, project: project_ext) }
      let!(:resource_3) { create(:ci_catalog_resource, project: project_b) }

      it 'returns only resources for public projects' do
        is_expected.to contain_exactly(resource_1, resource_2)
      end

      context 'when sorting is provided' do
        let(:params) { { sort: :name_desc } }

        it 'returns only resources for public projects sorted by name DESC' do
          is_expected.to contain_exactly(resource_2, resource_1)
        end
      end
    end

    context 'when search params are provided' do
      let(:params) { { search: 'test' } }

      let!(:resource_1) { create(:ci_catalog_resource, project: project_a) }
      let!(:resource_2) { create(:ci_catalog_resource, project: project_ext) }
      let!(:resource_3) { create(:ci_catalog_resource, project: project_b) }

      it 'returns the resources that match the search params' do
        is_expected.to contain_exactly(resource_2, resource_3)
      end

      context 'when search term is too small' do
        let(:params) { { search: 'te' } }

        it { is_expected.to be_empty }
      end
    end

    context 'when namespace is provided' do
      let(:params) { { namespace: namespace } }

      context 'when namespace is not a root namespace' do
        let(:namespace) { create(:group, :nested) }

        it 'raises an exception' do
          expect { resources }.to raise_error(ArgumentError, 'Namespace is not a root namespace')
        end
      end

      context 'when the user has access to all projects in the namespace' do
        context 'when the namespace has no catalog resources' do
          it { is_expected.to be_empty }
        end

        context 'when the namespace has catalog resources' do
          let_it_be(:today) { Time.zone.now }
          let_it_be(:yesterday) { today - 1.day }
          let_it_be(:tomorrow) { today + 1.day }

          let_it_be(:resource_1) do
            create(:ci_catalog_resource, project: project_x, latest_released_at: yesterday)
          end

          let_it_be(:resource_2) do
            create(:ci_catalog_resource, project: project_b, latest_released_at: today)
          end

          let_it_be(:resource_3) do
            create(:ci_catalog_resource, project: project_a, latest_released_at: nil)
          end

          let_it_be(:other_namespace_resource) do
            create(:ci_catalog_resource, project: project_ext, latest_released_at: tomorrow)
          end

          it 'contains only catalog resources for projects in that namespace' do
            is_expected.to contain_exactly(resource_1, resource_2, resource_3)
          end

          context 'with a sort parameter' do
            let(:params) { { namespace: namespace, sort: sort } }

            context 'when the sort is name ascending' do
              let_it_be(:sort) { :name_asc }

              it 'contains catalog resources for projects sorted by name ascending' do
                is_expected.to eq([resource_3, resource_2, resource_1])
              end
            end

            context 'when the sort is name descending' do
              let_it_be(:sort) { :name_desc }

              it 'contains catalog resources for projects sorted by name descending' do
                is_expected.to eq([resource_1, resource_2, resource_3])
              end
            end

            context 'when the sort is latest_released_at ascending' do
              let_it_be(:sort) { :latest_released_at_asc }

              it 'contains catalog resources sorted by latest_released_at ascending with nulls last' do
                is_expected.to eq([resource_1, resource_2, resource_3])
              end
            end

            context 'when the sort is latest_released_at descending' do
              let_it_be(:sort) { :latest_released_at_desc }

              it 'contains catalog resources sorted by latest_released_at descending with nulls last' do
                is_expected.to eq([resource_2, resource_1, resource_3])
              end
            end
          end
        end
      end

      context 'when the user only has access to some projects in the namespace' do
        let!(:accessible_resource) { create(:ci_catalog_resource, project: project_x) }
        let!(:inaccessible_resource) { create(:ci_catalog_resource, project: project_noaccess) }

        it 'only returns catalog resources for projects the user has access to' do
          is_expected.to contain_exactly(accessible_resource)
        end
      end

      context 'when the user does not have access to the namespace' do
        let!(:project) { create(:project) }
        let!(:resource) { create(:ci_catalog_resource, project: project) }

        let(:namespace) { project.namespace }

        it { is_expected.to be_empty }
      end
    end
  end
end
