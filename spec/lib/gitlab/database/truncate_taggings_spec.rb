# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TruncateTaggings, feature_category: :database do
  include MigrationsHelpers

  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  let(:taggings) { table(:taggings, database: :ci) }

  describe '#execute' do
    context 'when the table has data' do
      before do
        taggings.create!
      end

      context 'when executed on .com' do
        before do
          allow(Gitlab).to receive(:com_except_jh?).and_return(true)
        end

        it 'truncates taggings' do
          recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

          expect(recorder.log).to include(/TRUNCATE TABLE "taggings"/)
        end
      end

      it 'is a no-op everywhere else' do
        recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

        expect(recorder.log).to be_empty
      end
    end

    context 'when the table is empty' do
      context 'when executed on .com' do
        before do
          allow(Gitlab).to receive(:com_except_jh?).and_return(true)
        end

        it 'does not truncate taggings' do
          recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

          expect(recorder.log).not_to include(/TRUNCATE TABLE "taggings"/)
        end
      end
    end
  end
end
