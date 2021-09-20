# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter do
  subject { described_class.import }

  it_behaves_like 'work item base types importer'
end
