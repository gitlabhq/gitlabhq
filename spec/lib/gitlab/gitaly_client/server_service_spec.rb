# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::ServerService, feature_category: :gitaly do
  let_it_be(:project) { create(:project, :repository) }
  let(:storage_name) { project.repository_storage }
  let(:client) { described_class.new(storage_name) }

  describe '#server_signature' do
    it 'sends a server_signature message' do
      # rubocop:disable RSpec/AnyInstanceOf -- expect_next_instance_of does not work here
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163430#note_2086684781
      expect_any_instance_of(Gitaly::ServerService::Stub).to receive(:server_signature).and_return([])
      # rubocop:enable RSpec/AnyInstanceOf

      client.server_signature
    end
  end
end
