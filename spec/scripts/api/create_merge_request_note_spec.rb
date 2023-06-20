# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/api/create_merge_request_note'

RSpec.describe CreateMergeRequestNote, feature_category: :tooling do
  describe '#execute' do
    let(:project_id) { 12345 }
    let(:iid) { 1 }
    let(:content) { 'test123' }

    let(:options) do
      {
        api_token: 'token',
        endpoint: 'https://example.gitlab.com',
        project: project_id,
        merge_request: Struct.new(:iid).new(iid)
      }
    end

    subject { described_class.new(options) }

    it 'requests create_merge_request_comment from the gitlab client' do
      client = double('Gitlab::Client') # rubocop:disable RSpec/VerifiedDoubles

      expect(Gitlab).to receive(:client)
                          .with(endpoint: options[:endpoint], private_token: options[:api_token])
                          .and_return(client)

      expect(client).to receive(:create_merge_request_comment).with(
        project_id, iid, content
      ).and_return(true)

      subject.execute(content)
    end
  end
end
