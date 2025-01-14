# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Logger, feature_category: :importers do
  subject(:logger) { described_class.new('/dev/null') }

  it_behaves_like 'a json logger', { 'feature_category' => 'importers', 'import_type' => 'github' }
end
