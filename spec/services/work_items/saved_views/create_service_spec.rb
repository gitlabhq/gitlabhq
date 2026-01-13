# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::CreateService, feature_category: :portfolio_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, developers: [current_user]) }
  let_it_be(:project) { create(:project, group: group, developers: [current_user]) }

  let(:container) { project }
  let(:params) do
    { name: 'My Saved View',
      description: 'Desc',
      filters: { state: 'opened' },
      display_settings: { hiddenMetadataKeys: [] },
      sort: :created_asc }
  end

  subject(:service) { described_class.new(current_user: current_user, container: container, params: params) }

  describe '#execute' do
    context 'when saved views are enabled' do
      context 'with valid params' do
        it 'creates a saved view' do
          result = service.execute

          expect(result).to be_success
          saved_view = result.payload[:saved_view]
          expect(saved_view).to be_persisted
          expect(saved_view.name).to eq('My Saved View')
          expect(saved_view.author).to eq(current_user)
        end

        context 'when container is a project' do
          let(:container) { project }

          it 'creates saved view with project namespace' do
            result = service.execute

            expect(result).to be_success
            expect(result.payload[:saved_view].namespace).to eq(project.project_namespace)
          end
        end

        context 'when container is a group' do
          let(:container) { group }

          it 'creates saved view with namespace' do
            result = service.execute

            expect(result).to be_success
            expect(result.payload[:saved_view].namespace).to eq(group)
          end
        end
      end

      context 'with invalid params' do
        let(:params) { { name: '', filters: { state: 'opened' } } }

        it 'returns an error' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to include("Name can't be blank")
        end
      end

      context 'when filter normalization fails' do
        let(:params) { { name: 'My View', filters: { invalid_filter: 'value' }, private: false } }

        before do
          allow_next_instance_of(WorkItems::SavedViews::FilterNormalizerService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Invalid filter'))
          end
        end

        it 'returns the error from filter normalization' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Invalid filter')
        end
      end
    end

    context 'when saved views are not enabled' do
      before do
        allow(container).to receive(:work_items_saved_views_enabled?).and_return(false)
      end

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Saved views are not enabled for this namespace.')
      end
    end

    context 'when container is nil' do
      let(:container) { nil }

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Saved views are not enabled for this namespace.')
      end
    end

    context 'when user does not have permission' do
      let(:unauthorized_user) { create(:user) }
      let(:service) { described_class.new(current_user: unauthorized_user, container: container, params: params) }

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('You do not have permission to create saved views in this namespace.')
      end

      it 'does not create a saved view' do
        expect { service.execute }.not_to change { WorkItems::SavedViews::SavedView.count }
      end
    end
  end
end
