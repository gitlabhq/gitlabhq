# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::SchemaInconsistency, type: :model, feature_category: :database do
  it { is_expected.to be_a ApplicationRecord }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:object_name) }
    it { is_expected.to validate_presence_of(:valitador_name) }
    it { is_expected.to validate_presence_of(:table_name) }
    it { is_expected.to validate_presence_of(:diff) }
  end

  describe 'scopes' do
    describe '.with_open_issues' do
      subject(:inconsistencies) { described_class.with_open_issues }

      let(:closed_issue) { create(:issue, :closed) }
      let(:open_issue) { create(:issue, :opened) }

      let!(:schema_inconsistency_with_issue_closed) do
        create(:schema_inconsistency, object_name: 'index_name', table_name: 'achievements',
          valitador_name: 'different_definition_indexes', issue: closed_issue)
      end

      let!(:schema_inconsistency_with_issue_opened) do
        create(:schema_inconsistency, object_name: 'index_name', table_name: 'achievements',
          valitador_name: 'different_definition_indexes', issue: open_issue)
      end

      it 'returns only schema inconsistencies with GitLab issues open' do
        expect(inconsistencies).to eq([schema_inconsistency_with_issue_opened])
      end
    end
  end
end
