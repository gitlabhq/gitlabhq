# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::DiffNotes::DiscussionId, :clean_gitlab_redis_shared_state,
  feature_category: :importers do
  describe '#discussion_id' do
    let(:hunk) do
      '@@ -1 +1 @@
      -Hello
      +Hello world'
    end

    let(:note_id) { 1 }
    let(:html_url) { 'https://github.com/foo/project_name/pull/42' }
    let(:note) do
      {
        id: note_id,
        html_url: html_url,
        path: 'README.md',
        commit_id: '123abc',
        original_commit_id: 'original123abc',
        side: 'RIGHT',
        user: { id: 4, login: 'alice' },
        diff_hunk: hunk,
        body: 'Hello world',
        created_at: Time.new(2017, 1, 1, 12, 10).utc,
        updated_at: Time.new(2017, 1, 1, 12, 15).utc,
        line: 23,
        start_line: nil,
        in_reply_to_id: nil
      }
    end

    context 'when the note is not a reply to a discussion' do
      subject(:discussion_id) { described_class.new(note).find_or_generate }

      it 'generates and caches new discussion_id' do
        expect(Discussion)
          .to receive(:discussion_id)
          .and_return('FIRST_DISCUSSION_ID')

        expect(Gitlab::Cache::Import::Caching).to receive(:write).with(
          "github-importer/discussion-id-map/project_name/42/#{note_id}",
          'FIRST_DISCUSSION_ID'
        ).and_return('FIRST_DISCUSSION_ID')

        expect(discussion_id).to eq('FIRST_DISCUSSION_ID')
      end
    end

    context 'when the note is a reply to a discussion' do
      let(:reply_note) do
        {
          note_id: note_id + 1,
          in_reply_to_id: note_id,
          html_url: html_url
        }
      end

      subject(:discussion_id) { described_class.new(reply_note).find_or_generate }

      it 'uses the cached value as the discussion_id' do
        expect(Discussion)
          .to receive(:discussion_id)
          .and_return('FIRST_DISCUSSION_ID')

        described_class.new(note).find_or_generate

        expect(discussion_id).to eq('FIRST_DISCUSSION_ID')
      end

      context 'when cached value does not exist' do
        it 'falls back to generating a new discussion_id' do
          expect(Discussion)
            .to receive(:discussion_id)
            .and_return('NEW_DISCUSSION_ID')

          expect(discussion_id).to eq('NEW_DISCUSSION_ID')
        end
      end
    end
  end
end
