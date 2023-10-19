# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventSetOperatorMismatch::References,
  feature_category: :cell do
  include PreventSetOperatorMismatchHelper

  let(:refs) do
    {
      'resolved_reference' => Set.new,
      'unresolved_reference' => double,
      'table_reference' => PgQuery::RangeVar.new,
      'error_reference' => [Type::INVALID].to_set
    }
  end

  describe '.resolved' do
    subject { described_class.resolved(refs) }

    it { is_expected.to eq refs.slice('resolved_reference', 'error_reference') }
  end

  describe '.unresolved' do
    subject { described_class.unresolved(refs) }

    it { is_expected.to eq refs.slice('unresolved_reference') }
  end

  describe '.errors?' do
    subject { described_class.errors?(refs) }

    it { is_expected.to be_truthy }

    context 'when no errors exist' do
      subject { described_class.errors?(refs.except('error_reference')) }

      it { is_expected.to be_falsey }
    end
  end
end
