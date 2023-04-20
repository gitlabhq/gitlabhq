# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Slug::Environment, feature_category: :environment_management do
  describe '#generate' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(name).generate }

    before do
      # ('a' * 64).to_i(16).to_s(36).last(6) gives 'q517sa'
      allow(Digest::SHA2).to receive(:hexdigest).with(name.to_s).and_return('a' * 64)
    end

    where(:name, :slug) do
      "staging-12345678901234567" | "staging-123456789-q517sa"
      "9-staging-123456789012345" | "env-9-staging-123-q517sa"
      "staging-1234567890123456"  | "staging-1234567890123456"
      "staging-1234567890123456-" | "staging-123456789-q517sa"
      "production"                | "production"
      "PRODUCTION"                | "production-q517sa"
      "review/1-foo"              | "review-1-foo-q517sa"
      "1-foo"                     | "env-1-foo-q517sa"
      "1/foo"                     | "env-1-foo-q517sa"
      "foo-"                      | "foo"
      "foo--bar"                  | "foo-bar-q517sa"
      "foo**bar"                  | "foo-bar-q517sa"
      "*-foo"                     | "env-foo-q517sa"
      "staging-12345678-"         | "staging-12345678"
      "staging-12345678-01234567" | "staging-12345678-q517sa"
      ""                          | "env-q517sa"
      nil                         | "env-q517sa"
    end

    with_them do
      it { is_expected.to eq(slug) }
    end
  end
end
