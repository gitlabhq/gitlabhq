# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RefMatcher, feature_category: :source_code_management do
  subject(:ref_matcher) { described_class.new(ref_pattern) }

  describe '#matching' do
    it_behaves_like 'RefMatcher#matching'
  end

  describe '#matches?' do
    it_behaves_like 'RefMatcher#matches?'
  end

  describe '#wildcard?' do
    it_behaves_like 'RefMatcher#wildcard?'
  end
end
