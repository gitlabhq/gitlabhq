# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Listing, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project_1) { create(:project, namespace: namespace, name: 'X Project') }
  let_it_be(:project_2) { create(:project, namespace: namespace, name: 'B Project') }
  let_it_be(:project_3) { create(:project, namespace: namespace, name: 'A Project') }
  let_it_be(:project_4) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:list) { described_class.new(namespace, user) }

  describe '#new' do
    context 'when namespace is not a root namespace' do
      let(:namespace) { create(:group, :nested) }

      it 'raises an exception' do
        expect { list }.to raise_error(ArgumentError, 'Namespace is not a root namespace')
      end
    end
  end

  describe '#resources' do
    subject(:resources) { list.resources }

    context 'when the user has access to all projects in the namespace' do
      before do
        namespace.add_developer(user)
      end

      context 'when the namespace has no catalog resources' do
        it { is_expected.to be_empty }
      end

      context 'when the namespace has catalog resources' do
        let_it_be(:today) { Time.zone.now }
        let_it_be(:yesterday) { today - 1.day }
        let_it_be(:tomorrow) { today + 1.day }

        let_it_be(:resource) { create(:ci_catalog_resource, project: project_1, latest_released_at: yesterday) }
        let_it_be(:resource_2) { create(:ci_catalog_resource, project: project_2, latest_released_at: today) }
        let_it_be(:resource_3) { create(:ci_catalog_resource, project: project_3, latest_released_at: nil) }

        let_it_be(:other_namespace_resource) do
          create(:ci_catalog_resource, project: project_4, latest_released_at: tomorrow)
        end

        it 'contains only catalog resources for projects in that namespace' do
          is_expected.to contain_exactly(resource, resource_2, resource_3)
        end

        context 'with a sort parameter' do
          subject(:resources) { list.resources(sort: sort) }

          context 'when the sort is name ascending' do
            let_it_be(:sort) { :name_asc }

            it 'contains catalog resources for projects sorted by name ascending' do
              is_expected.to eq([resource_3, resource_2, resource])
            end
          end

          context 'when the sort is name descending' do
            let_it_be(:sort) { :name_desc }

            it 'contains catalog resources for projects sorted by name descending' do
              is_expected.to eq([resource, resource_2, resource_3])
            end
          end

          context 'when the sort is latest_released_at ascending' do
            let_it_be(:sort) { :latest_released_at_asc }

            it 'contains catalog resources sorted by latest_released_at ascending with nulls last' do
              is_expected.to eq([resource, resource_2, resource_3])
            end
          end

          context 'when the sort is latest_released_at descending' do
            let_it_be(:sort) { :latest_released_at_desc }

            it 'contains catalog resources sorted by latest_released_at descending with nulls last' do
              is_expected.to eq([resource_2, resource, resource_3])
            end
          end
        end
      end
    end

    context 'when the user only has access to some projects in the namespace' do
      let!(:resource_1) { create(:ci_catalog_resource, project: project_1) }
      let!(:resource_2) { create(:ci_catalog_resource, project: project_2) }

      before do
        project_1.add_developer(user)
        project_2.add_guest(user)
      end

      it 'only returns catalog resources for projects the user has access to' do
        is_expected.to contain_exactly(resource_1)
      end
    end

    context 'when the user does not have access to the namespace' do
      let!(:resource) { create(:ci_catalog_resource, project: project_1) }

      it { is_expected.to be_empty }
    end
  end
end
