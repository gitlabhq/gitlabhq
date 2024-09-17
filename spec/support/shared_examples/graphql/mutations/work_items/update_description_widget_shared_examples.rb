# frozen_string_literal: true

RSpec.shared_examples 'update work item description widget' do
  it 'updates the description widget' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
      work_item.reload
    end.to change { work_item.description }.from(nil).to(new_description)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['workItem']['widgets']).to include(
      {
        'type' => 'DESCRIPTION',
        'description' => new_description,
        'lastEditedAt' => Time.current,
        'lastEditedBy' => {
          'id' => current_user.to_global_id.to_s
        }
      }
    )
  end

  context 'when the updated work item is not valid' do
    it 'returns validation errors without the work item' do
      errors = ActiveModel::Errors.new(work_item).tap { |e| e.add(:description, 'error message') }

      allow_next_found_instance_of(::WorkItem) do |instance|
        allow(instance).to receive(:valid?).and_return(false)
        allow(instance).to receive(:errors).and_return(errors)
      end

      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['workItem']).to be_nil
      expect(mutation_response['errors']).to match_array(['Description error message'])
    end
  end

  context 'when the edited description includes quick action(s)' do
    let(:input) { { 'descriptionWidget' => { 'description' => new_description } } }

    shared_examples 'quick action is applied' do
      before do
        post_graphql_mutation(mutation, current_user: current_user)
      end

      it 'applies the quick action(s)' do
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']).to include(expected_response)
      end
    end

    context 'with /title quick action' do
      it_behaves_like 'quick action is applied' do
        let(:new_description) { "updated description\n/title updated title" }
        let(:filtered_description) { "updated description" }

        let(:expected_response) do
          {
            'title' => 'updated title',
            'widgets' => include(a_hash_including({
              'description' => filtered_description,
              'type' => 'DESCRIPTION'
            }))
          }
        end
      end
    end

    context 'with /shrug, /tableflip and /cc quick action' do
      it_behaves_like 'quick action is applied' do
        let(:new_description) { "/tableflip updated description\n/shrug\n/cc @#{developer.username}" }
        # note: \cc performs no action since 15.0
        let(:filtered_description) { "(╯°□°)╯︵ ┻━┻\n¯\\＿(ツ)＿/¯\n/cc @#{developer.username}" }
        let(:expected_response) do
          {
            'widgets' => include(a_hash_including({
              'description' => filtered_description,
              'type' => 'DESCRIPTION'
            }))
          }
        end
      end
    end

    context 'with /close' do
      it_behaves_like 'quick action is applied' do
        let(:new_description) { "Resolved work item.\n/close" }
        let(:filtered_description) { "Resolved work item." }
        let(:expected_response) do
          {
            'state' => 'CLOSED',
            'widgets' => include(a_hash_including({
              'description' => filtered_description,
              'type' => 'DESCRIPTION'
            }))
          }
        end
      end
    end

    context 'with /reopen' do
      before do
        work_item.close!
      end

      it_behaves_like 'quick action is applied' do
        let(:new_description) { "Re-opening this work item.\n/reopen" }
        let(:filtered_description) { "Re-opening this work item." }
        let(:expected_response) do
          {
            'state' => 'OPEN',
            'widgets' => include(a_hash_including({
              'description' => filtered_description,
              'type' => 'DESCRIPTION'
            }))
          }
        end
      end
    end
  end
end
