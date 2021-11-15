# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UserMentions::CreateResourceUserMention, schema: 20181228175414 do
  context 'checks no_quote_columns' do
    it 'has correct no_quote_columns' do
      expect(Gitlab::BackgroundMigration::UserMentions::Models::MergeRequest.no_quote_columns).to match([:note_id, :merge_request_id])
    end

    it 'commit has correct no_quote_columns' do
      expect(Gitlab::BackgroundMigration::UserMentions::Models::Commit.no_quote_columns).to match([:note_id])
    end
  end
end
