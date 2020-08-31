# frozen_string_literal: true

RSpec.shared_examples 'when the snippet is not found' do
  let(:snippet_gid) do
    "gid://gitlab/#{snippet.class.name}/#{non_existing_record_id}"
  end

  it_behaves_like 'a mutation that returns top-level errors',
                  errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
end

RSpec.shared_examples 'snippet edit usage data counters' do
  context 'when user is sessionless' do
    it 'does not track usage data actions' do
      expect(::Gitlab::UsageDataCounters::EditorUniqueCounter).not_to receive(:track_snippet_editor_edit_action)

      post_graphql_mutation(mutation, current_user: current_user)
    end
  end

  context 'when user is not sessionless' do
    before do
      session_id = Rack::Session::SessionId.new('6919a6f1bb119dd7396fadc38fd18d0d')
      session_hash = { 'warden.user.user.key' => [[current_user.id], current_user.encrypted_password[0, 29]] }

      Gitlab::Redis::SharedState.with do |redis|
        redis.set("session:gitlab:#{session_id.private_id}", Marshal.dump(session_hash))
      end

      cookies[Gitlab::Application.config.session_options[:key]] = session_id.public_id
    end

    it 'tracks usage data actions', :clean_gitlab_redis_shared_state do
      expect(::Gitlab::UsageDataCounters::EditorUniqueCounter).to receive(:track_snippet_editor_edit_action)

      post_graphql_mutation(mutation)
    end

    context 'when mutation result raises an error' do
      it 'does not track usage data actions' do
        mutation_vars[:title] = nil

        expect(::Gitlab::UsageDataCounters::EditorUniqueCounter).not_to receive(:track_snippet_editor_edit_action)

        post_graphql_mutation(mutation)
      end
    end
  end
end
