# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Console, feature_category: :database do
  describe '.run' do
    let(:output) { StringIO.new }
    let(:runner) { instance_double(described_class::Runner, run: 'warning') }

    it 'runs every registered view by default' do
      expect(described_class::Runner).to receive(:new)
        .with(database_names: %w[main], views: described_class::VIEWS.values, output: output)
        .and_return(runner)

      expect(described_class.run(database_names: %w[main], output: output)).to eq('warning')
    end

    it 'runs only the requested checks' do
      expect(described_class::Runner).to receive(:new)
        .with(database_names: %w[main], views: [described_class::Views::SchemaResolution], output: output)
        .and_return(runner)

      result = described_class.run(database_names: %w[main], check_names: %w[search_path], output: output)

      expect(result).to eq('warning')
    end

    it 'runs every registered view when check_names is empty' do
      expect(described_class::Runner).to receive(:new)
        .with(database_names: %w[main], views: described_class::VIEWS.values, output: output)
        .and_return(runner)

      described_class.run(database_names: %w[main], check_names: [], output: output)
    end

    it 'runs a repeated check once' do
      expect(described_class::Runner).to receive(:new)
        .with(database_names: %w[main], views: [described_class::Views::SchemaResolution], output: output)
        .and_return(runner)

      described_class.run(database_names: %w[main], check_names: %w[search_path search_path], output: output)
    end

    it 'accepts symbol check names' do
      expect(described_class::Runner).to receive(:new)
        .with(database_names: %w[main], views: [described_class::Views::SchemaResolution], output: output)
        .and_return(runner)

      described_class.run(database_names: %w[main], check_names: [:search_path], output: output)
    end

    it 'raises on an unknown check name' do
      expect { described_class.run(database_names: %w[main], check_names: %w[nope], output: output) }
        .to raise_error(described_class::UnknownCheckError, /Unknown check\(s\): nope\. Valid: search_path/)
    end
  end

  describe '.summarize' do
    where(:counts, :expected) do
      [
        [{}, nil],
        [{ 'error' => 1 }, '1 error'],
        [{ 'warning' => 2 }, '2 warnings'],
        [{ 'warning' => 2, 'error' => 1 }, '1 error, 2 warnings'],
        [{ 'notice' => 1, 'error' => 1 }, '1 error, 1 notice']
      ]
    end

    with_them do
      it { expect(described_class.summarize(counts)).to eq(expected) }
    end
  end

  describe '.merge_counts' do
    it 'sums each severity across every hash' do
      merged = described_class.merge_counts([{ 'error' => 1, 'warning' => 1 }, { 'warning' => 2 }])

      expect(merged).to eq({ 'error' => 1, 'warning' => 3 })
    end

    it 'returns an empty hash for no input' do
      expect(described_class.merge_counts([])).to eq({})
    end
  end
end
