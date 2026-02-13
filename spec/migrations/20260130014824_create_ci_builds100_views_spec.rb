# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateCiBuilds100Views, feature_category: :continuous_integration do
  let(:view_prefix) { described_class::VIEW_PREFIX }
  let(:boundaries) { described_class::VIEW_BOUNDARIES.each_cons(2).to_a }

  describe '#up' do
    context 'when on GitLab.com', :aggregate_failures do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'creates 4 views with correct boundaries' do
        migrate!

        (1..4).each do |view_number|
          expect(view_exists?(view_number)).to be true

          query = get_view_definition(view_number).squish
          lower_bound, upper_bound = boundaries[view_number - 1].minmax

          expect(query).to match(/id >= '?#{lower_bound}'?/)
          expect(query).to match(/id < '?#{upper_bound}'?/)
          expect(query).to include('partition_id = 100')
        end
      end
    end

    context 'when not on GitLab.com', :aggregate_failures do
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

    context 'when not on GitLab.com', :aggregate_failures do
      it 'does not attempt to drop views' do
        expect { schema_migrate_down! }.not_to raise_error
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
      WHERE table_schema = 'gitlab_partitions_dynamic'
      AND table_name = 'ci_builds_views_100_#{view_number}'
    SQL

    result.first['view_definition'] if result.any?
  end
end
