# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Teamcity, :use_clean_rails_memory_store_caching, feature_category: :integrations do
  it_behaves_like Integrations::Base::Teamcity do
    describe '#execute' do
      context 'when push' do
        let(:data) do
          {
            object_kind: 'push',
            ref: 'refs/heads/dev-123_branch',
            after: '0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e',
            total_commits_count: 1
          }
        end

        it 'handles push request correctly' do
          stub_post_to_build_queue(branch: 'dev-123_branch')

          expect(integration.execute(data)).to include('Ok')
        end

        it 'returns nil when ref is blank' do
          data[:after] = Gitlab::Git::SHA1_BLANK_SHA

          expect(integration.execute(data)).to be_nil
        end

        it 'returns nil when there is no content' do
          data[:total_commits_count] = 0

          expect(integration.execute(data)).to be_nil
        end

        it 'returns nil when a merge request is opened for the same ref' do
          create(:merge_request, source_project: project, source_branch: 'dev-123_branch')

          expect(integration.execute(data)).to be_nil
        end
      end

      context 'when merge_request' do
        let(:data) do
          {
            object_kind: 'merge_request',
            ref: 'refs/heads/dev-123_branch',
            after: '0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e',
            total_commits_count: 1,
            object_attributes: {
              state: 'opened',
              source_branch: 'dev-123_branch',
              merge_status: 'unchecked'
            }
          }
        end

        it 'handles merge request correctly' do
          stub_post_to_build_queue(branch: 'dev-123_branch')

          expect(integration.execute(data)).to include('Ok')
        end

        it 'returns nil when merge request is not opened' do
          data[:object_attributes][:state] = 'closed'

          expect(integration.execute(data)).to be_nil
        end

        it 'returns nil unless merge request is marked as unchecked' do
          data[:object_attributes][:merge_status] = 'can_be_merged'

          expect(integration.execute(data)).to be_nil
        end
      end

      it 'returns nil when event is not supported' do
        data = { object_kind: 'foo' }

        expect(integration.execute(data)).to be_nil
      end
    end
  end
end
