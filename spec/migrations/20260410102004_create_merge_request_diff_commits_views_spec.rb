# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateMergeRequestDiffCommitsViews, feature_category: :code_review_workflow do
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:lower_bounds) { described_class::VIEW_LOWER_BOUNDS }

  describe '#up' do
    context 'when on GitLab.com', :aggregate_failures do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      after do
        # Clean up views created by this test
        (1..4).each do |view_number|
          ApplicationRecord.connection.execute("DROP VIEW IF EXISTS #{view_prefix}_#{view_number}")
        end
      end

      it 'creates 4 views with correct boundaries' do
        migrate!

        lower_bounds.each_with_index do |lower, index|
          view_number = index + 1
          upper = lower_bounds[index + 1]

          expect(view_exists?(view_number)).to be true

          query = get_view_definition(view_number)

          expect(query).to include("ROW(#{lower[0]}, #{lower[1]})")

          if upper
            expect(query).to include("ROW(#{upper[0]}, #{upper[1]})")
          else
            expect(query).not_to include("< ROW")
          end
        end
      end
    end

    context 'when not on GitLab.com', :aggregate_failures do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not create views' do
        migrate!

        (1..4).each do |view_number|
          expect(view_exists?(view_number)).to be false
        end
      end
    end
  end

  describe '#down' do
    context 'when on GitLab.com', :aggregate_failures do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'drops all 4 views' do
        migrate!
        schema_migrate_down!

        (1..4).each do |view_number|
          expect(view_exists?(view_number)).to be false
        end
      end
    end
  end

  private

  def view_exists?(view_number)
    ApplicationRecord.connection.view_exists?("#{view_prefix}_#{view_number}")
  end

  def get_view_definition(view_number)
    result = ApplicationRecord.connection.execute(<<~SQL)
      SELECT view_definition FROM information_schema.views
      WHERE table_name = '#{view_prefix}_#{view_number}'
    SQL

    result.first['view_definition'] if result.any?
  end
end
