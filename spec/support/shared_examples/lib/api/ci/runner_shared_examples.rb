# frozen_string_literal: true

RSpec.shared_examples 'API::CI::Runner application context metadata' do |api_route|
  it 'contains correct context metadata' do
    # Avoids popping the context from the thread so we can
    # check its content after the request.
    allow(Labkit::Context).to receive(:pop)

    send_request

    Gitlab::ApplicationContext.with_raw_context do |context|
      expected_context = {
        'meta.caller_id' => api_route,
        'meta.user' => job.user.username,
        'meta.project' => job.project.full_path,
        'meta.root_namespace' => job.project.full_path_components.first
      }

      expect(context.to_h).to include(expected_context)
    end
  end
end
