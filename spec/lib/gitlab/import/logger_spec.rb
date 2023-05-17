# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Logger do
  subject { described_class.new('/dev/null') }

  it_behaves_like 'a json logger', { 'feature_category' => 'importers' }
end
