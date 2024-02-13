# frozen_string_literal: true

RSpec.shared_examples 'when the snippet is not found' do
  let(:snippet_gid) do
    "gid://gitlab/#{snippet.class.name}/#{non_existing_record_id}"
  end

  it_behaves_like 'a mutation that returns top-level errors',
    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
end

RSpec.shared_examples 'snippet edit usage data counters' do
  include SessionHelpers

  context 'when user is sessionless' do
    it 'does not track usage data actions' do
      expect(::Gitlab::InternalEvents).not_to receive(:track_event)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when user is not sessionless', :clean_gitlab_redis_sessions do
    before do
      stub_session('warden.user.user.key' => [[current_user.id], current_user.authenticatable_salt])
    end

    subject do
      post_graphql_mutation(mutation)
    end

    it_behaves_like 'internal event tracking' do
      let(:event) { 'g_edit_by_snippet_ide' }
    end

    context 'when mutation result raises an error' do
      it 'does not track usage data actions' do
        mutation_vars[:title] = nil

        expect(::Gitlab::InternalEvents).not_to receive(:track_event)

        post_graphql_mutation(mutation)
      end
    end
  end
end
