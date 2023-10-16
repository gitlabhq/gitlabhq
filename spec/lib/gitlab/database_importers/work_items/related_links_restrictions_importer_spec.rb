# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter,
  feature_category: :portfolio_management do
  subject { described_class.upsert_restrictions }

  it_behaves_like 'work item related links restrictions importer'
end
