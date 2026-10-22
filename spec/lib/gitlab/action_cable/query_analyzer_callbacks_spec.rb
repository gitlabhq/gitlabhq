# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ActionCable::QueryAnalyzerCallbacks, query_analyzers: false, feature_category: :database do
  describe '.wrapper' do
    let(:analyzer) { class_double(Gitlab::Database::QueryAnalyzers::Base) }

    before do
      allow(analyzer).to receive_messages(enabled?: true, suppressed?: false, skip_cached?: false)
      allow(analyzer).to receive(:begin!)
      allow(analyzer).to receive(:end!)
      allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return([analyzer])
    end

    it 'analyzes queries run by the inner block', :aggregate_failures do
      expect(analyzer).to receive(:analyze) do |parsed|
        expect(parsed.raw).to include('SELECT 1 FROM projects')
      end

      described_class.wrapper.call(nil, -> { Project.connection.execute('SELECT 1 FROM projects') })

      expect(analyzer).to have_received(:end!)
    end
  end
end
