# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::UpdateService, feature_category: :portfolio_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:project) { create(:project, planners: current_user) }

  let_it_be_with_reload(:saved_view) do
    create(:saved_view,
      namespace: project.project_namespace,
      author: current_user,
      name: 'Original Name',
      description: 'Original Description',
      private: false
    )
  end

  let(:params) { { name: 'Updated Name' } }

  subject(:service) do
    described_class.new(current_user: current_user, saved_view: saved_view, params: params)
  end

  describe '#execute' do
    context 'when saved views are not enabled for the namespace' do
      before do
        stub_feature_flags(work_items_saved_views: false)
      end

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Saved views are not enabled for this namespace.')
      end
    end

    context 'when user does not have permission to update the saved view' do
      let(:service) do
        described_class.new(current_user: other_user, saved_view: saved_view, params: params)
      end

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('You do not have permission to update this saved view.')
      end
    end

    context 'with all optional arguments' do
      let(:params) do
        {
          name: 'Updated Name',
          description: 'Updated Description',
          filters: { assignee_usernames: [current_user.username] },
          display_settings: { hiddenMetadataKeys: %w[assignee labels] },
          sort: 'created_asc',
          private: true
        }
      end

      it 'updates all provided fields' do
        result = service.execute

        expect(result).to be_success

        updated_view = saved_view.reload
        expect(updated_view.name).to eq('Updated Name')
        expect(updated_view.description).to eq('Updated Description')
        expect(updated_view.filter_data).to eq({ 'assignee_ids' => [current_user.id] })
        expect(updated_view.display_settings).to eq({ 'hiddenMetadataKeys' => %w[assignee labels] })
        expect(updated_view.sort).to eq('created_asc')
        expect(updated_view.private).to be(true)
      end
    end

    context 'when updating visibility' do
      context 'without permission' do
        let_it_be(:other_saved_view) do
          create(:saved_view,
            namespace: project.project_namespace,
            author: other_user,
            private: false
          )
        end

        let(:params) { { private: true } }

        let(:service) do
          described_class.new(current_user: current_user, saved_view: other_saved_view, params: params)
        end

        it 'returns an error' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Only the author can change visibility settings')
        end
      end

      context 'when changing from private to public' do
        let_it_be(:private_view) do
          create(:saved_view,
            namespace: project.project_namespace,
            author: current_user,
            private: true
          )
        end

        let(:saved_view) { private_view }
        let(:params) { { private: false } }

        it 'changes visibility to public' do
          result = service.execute

          expect(result).to be_success
          expect(private_view.reload.private).to be(false)
        end
      end

      context 'when changing from public to private' do
        let(:params) { { private: true } }

        it 'changes visibility to private' do
          result = service.execute

          expect(result).to be_success
          expect(saved_view.reload.private).to be(true)
        end

        it 'unsubscribes other users' do
          create(:user_saved_view, saved_view: saved_view, user: current_user)
          create(:user_saved_view, saved_view: saved_view, user: other_user)

          service = described_class.new(
            current_user: current_user,
            saved_view: saved_view,
            params: params
          )

          expect { service.execute }.to change { saved_view.user_saved_views.count }.from(2).to(1)
          expect(saved_view.subscribed_users).to contain_exactly(current_user)
        end

        it 'does not unsubscribe users when already private' do
          saved_view.update!(private: true)

          create(:user_saved_view, saved_view: saved_view, user: current_user)
          create(:user_saved_view, saved_view: saved_view, user: other_user)

          service = described_class.new(
            current_user: current_user,
            saved_view: saved_view,
            params: params
          )

          expect { service.execute }.not_to change { saved_view.user_saved_views.count }
        end
      end
    end

    context 'when updating individual fields' do
      it 'updates only the name' do
        service = described_class.new(
          current_user: current_user,
          saved_view: saved_view,
          params: { name: 'Updated Name' }
        )
        result = service.execute

        expect(result).to be_success

        updated_view = saved_view.reload
        expect(updated_view.name).to eq('Updated Name')
        expect(updated_view.description).to eq('Original Description')
      end

      it 'updates only the description' do
        service = described_class.new(
          current_user: current_user,
          saved_view: saved_view,
          params: { description: 'New Description' }
        )
        result = service.execute

        expect(result).to be_success

        updated_view = saved_view.reload
        expect(updated_view.description).to eq('New Description')
        expect(updated_view.name).to eq('Original Name')
      end

      it 'updates only the filters' do
        service = described_class.new(
          current_user: current_user,
          saved_view: saved_view,
          params: { filters: { assignee_usernames: [current_user.username] } }
        )
        result = service.execute

        expect(result).to be_success
        expect(saved_view.reload.filter_data).to eq({ 'assignee_ids' => [current_user.id] })
      end

      it 'updates only the display settings' do
        service = described_class.new(
          current_user: current_user,
          saved_view: saved_view,
          params: { display_settings: { hiddenMetadataKeys: %w[assignee labels milestone] } }
        )
        result = service.execute

        expect(result).to be_success
        expect(saved_view.reload.display_settings).to eq(
          { 'hiddenMetadataKeys' => %w[assignee labels milestone] }
        )
      end

      it 'updates only the sort' do
        service = described_class.new(
          current_user: current_user,
          saved_view: saved_view,
          params: { sort: 'updated_desc' }
        )
        result = service.execute

        expect(result).to be_success
        expect(saved_view.reload.sort).to eq('updated_desc')
      end

      it 'updates only the private flag' do
        service = described_class.new(
          current_user: current_user,
          saved_view: saved_view,
          params: { private: true }
        )
        result = service.execute

        expect(result).to be_success
        expect(saved_view.reload.private).to be(true)
      end
    end

    context 'when the update fails' do
      let(:params) { { name: '' } }

      it 'returns an error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.errors).to be_present
      end

      it 'does not update the saved view' do
        original_name = saved_view.name

        service.execute

        expect(saved_view.reload.name).to eq(original_name)
      end
    end

    context 'when filter normalization fails' do
      let(:params) { { filters: { invalid: 'filter' } } }

      before do
        allow_next_instance_of(WorkItems::SavedViews::FilterNormalizerService) do |normalizer|
          allow(normalizer).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Invalid filter')
          )
        end
      end

      it 'returns the filter error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Invalid filter')
      end
    end
  end
end
