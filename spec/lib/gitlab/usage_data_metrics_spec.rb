# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataMetrics do
  describe '.uncached_data' do
    subject { described_class.uncached_data }

    around do |example|
      described_class.instance_variable_set(:@definitions, nil)
      example.run
      described_class.instance_variable_set(:@definitions, nil)
    end

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'with instrumentation_class' do
      it 'includes top level keys' do
        expect(subject).to include(:uuid)
        expect(subject).to include(:hostname)
      end

      it 'includes counts keys' do
        expect(subject[:counts]).to include(:boards)
      end

      it 'includes i_quickactions_approve monthly and weekly key' do
        expect(subject[:redis_hll_counters][:quickactions]).to include(:i_quickactions_approve_monthly)
        expect(subject[:redis_hll_counters][:quickactions]).to include(:i_quickactions_approve_weekly)
      end

      it 'includes ide_edit monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:ide_edit].keys).to contain_exactly(*[
          :g_edit_by_web_ide_monthly, :g_edit_by_web_ide_weekly,
          :g_edit_by_sfe_monthly, :g_edit_by_sfe_weekly,
          :g_edit_by_sse_monthly, :g_edit_by_sse_weekly,
          :g_edit_by_snippet_ide_monthly, :g_edit_by_snippet_ide_weekly,
          :ide_edit_total_unique_counts_monthly, :ide_edit_total_unique_counts_weekly
        ])
      end

      it 'includes source_code monthly and weekly keys' do
        expect(subject[:redis_hll_counters][:source_code].keys).to contain_exactly(*[
          :wiki_action_monthly, :wiki_action_weekly,
          :design_action_monthly, :design_action_weekly,
          :project_action_monthly, :project_action_weekly,
          :git_write_action_monthly, :git_write_action_weekly,
          :merge_request_action_monthly, :merge_request_action_weekly,
          :i_source_code_code_intelligence_monthly, :i_source_code_code_intelligence_weekly
        ])
      end

      it 'includes counts keys' do
        expect(subject[:counts]).to include(:issues)
      end

      it 'includes usage_activity_by_stage keys' do
        expect(subject[:usage_activity_by_stage][:plan]).to include(:issues)
      end

      it 'includes usage_activity_by_stage_monthly keys' do
        expect(subject[:usage_activity_by_stage_monthly][:plan]).to include(:issues)
      end

      it 'includes settings keys' do
        expect(subject[:settings]).to include(:collected_data_categories)
      end
    end
  end
end
