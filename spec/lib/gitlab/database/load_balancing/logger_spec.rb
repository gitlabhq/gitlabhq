# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Logger, feature_category: :database do
  subject { described_class.new('/dev/null') }

  it_behaves_like 'a json logger', {}

  it 'excludes context' do
    expect(described_class.exclude_context?).to be(true)
  end
end
