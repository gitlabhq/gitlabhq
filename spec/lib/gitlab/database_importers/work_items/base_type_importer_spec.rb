# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter, feature_category: :team_planning do
  subject { described_class.upsert_types }

  it_behaves_like 'work item base types importer'
end
