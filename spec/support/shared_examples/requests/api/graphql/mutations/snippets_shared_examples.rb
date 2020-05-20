# frozen_string_literal: true

RSpec.shared_examples 'when the snippet is not found' do
  let(:snippet_gid) do
    "gid://gitlab/#{snippet.class.name}/#{non_existing_record_id}"
  end

  it_behaves_like 'a mutation that returns top-level errors',
                  errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
end
