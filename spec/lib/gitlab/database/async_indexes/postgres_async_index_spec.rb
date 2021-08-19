# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::PostgresAsyncIndex, type: :model do
  describe 'validations' do
    let(:identifier_limit) { described_class::MAX_IDENTIFIER_LENGTH }
    let(:definition_limit) { described_class::MAX_DEFINITION_LENGTH }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_length_of(:table_name).is_at_most(identifier_limit) }
    it { is_expected.to validate_presence_of(:definition) }
    it { is_expected.to validate_length_of(:definition).is_at_most(definition_limit) }
  end
end
