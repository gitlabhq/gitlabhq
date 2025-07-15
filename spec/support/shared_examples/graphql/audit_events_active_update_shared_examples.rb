# frozen_string_literal: true

RSpec.shared_examples 'audits legacy active status changes' do
  context 'when only updating active status' do
    before do
      model.activate!
      allow(Gitlab::Audit::Auditor).to receive(:audit).and_call_original
    end

    let(:active_input) do
      {
        id: input[:id],
        active: false
      }
    end

    let(:mutation_with_active) { graphql_mutation(mutation_name, active_input) }

    it 'deactivates the model and creates a single audit event' do
      expect(Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(
          name: event_name,
          author: current_user,
          target: model,
          message: 'Changed active from true to false'
        )
      )

      post_graphql_mutation(mutation_with_active, current_user: current_user)

      model.reload
      expect(model.active?).to be false
      expect(mutation_response[mutation_field]['active']).to be false
      expect(mutation_response['errors']).to be_empty
    end

    context 'when model is already inactive' do
      before do
        model.deactivate!
      end

      it 'does not create an audit event' do
        expect(Gitlab::Audit::Auditor).not_to receive(:audit)

        post_graphql_mutation(mutation_with_active, current_user: current_user)

        expect(mutation_response['errors']).to be_empty
        expect(mutation_response[mutation_field]['active']).to be false
      end
    end
  end

  context 'when updating multiple attributes including active status' do
    before do
      model.activate!
      allow(Gitlab::Audit::Auditor).to receive(:audit).and_call_original
    end

    let(:mutation_with_combined) do
      graphql_mutation(
        mutation_name,
        input.merge(active: false)
      )
    end

    it 'updates all attributes and creates audit events for changes' do
      expect(Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(
          name: event_name,
          author: current_user,
          target: model,
          message: 'Changed active from true to false'
        )
      ).ordered

      post_graphql_mutation(mutation_with_combined, current_user: current_user)

      model.reload
      expect(model.active?).to be false
      expect(mutation_response[mutation_field]['active']).to be false
      expect(mutation_response['errors']).to be_empty
    end
  end
end

RSpec.shared_examples 'audits streaming active status changes' do
  context 'when only updating active status' do
    before do
      model.activate!
      allow(Gitlab::Audit::Auditor).to receive(:audit).and_call_original
    end

    let(:active_input) do
      {
        id: destination_gid,
        active: false
      }
    end

    let(:mutation_with_active) { graphql_mutation(mutation_name, active_input) }

    it 'deactivates the model and creates a single audit event' do
      expect(Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(
          name: event_name,
          author: current_user,
          target: model,
          message: 'Changed active from true to false'
        )
      )

      post_graphql_mutation(mutation_with_active, current_user: current_user)

      model.reload
      expect(model.active?).to be false

      response_destination = mutation_response[mutation_field]
      expect(response_destination).not_to be_nil
      expect(response_destination['active']).to be false
      expect(mutation_response['errors']).to be_empty
    end

    context 'when model is already inactive' do
      before do
        model.deactivate!
      end

      it 'does not create an audit event' do
        expect(Gitlab::Audit::Auditor).not_to receive(:audit)

        post_graphql_mutation(mutation_with_active, current_user: current_user)

        response_destination = mutation_response[mutation_field]
        expect(response_destination).not_to be_nil
        expect(response_destination['active']).to be false
        expect(mutation_response['errors']).to be_empty
      end
    end
  end

  context 'when updating multiple attributes including active status' do
    before do
      model.activate!
      allow(Gitlab::Audit::Auditor).to receive(:audit).and_call_original
    end

    let(:mutation_with_combined) do
      combined_input = input.dup
      combined_input[:active] = false

      graphql_mutation(mutation_name, combined_input)
    end

    it 'updates all attributes and creates audit events for changes' do
      expect(Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(
          name: event_name,
          author: current_user,
          target: model,
          message: 'Changed active from true to false'
        )
      ).ordered

      post_graphql_mutation(mutation_with_combined, current_user: current_user)

      model.reload
      expect(model.active?).to be false

      response_destination = mutation_response[mutation_field]
      expect(response_destination).not_to be_nil
      expect(response_destination['active']).to be false
      expect(mutation_response['errors']).to be_empty
    end
  end
end
