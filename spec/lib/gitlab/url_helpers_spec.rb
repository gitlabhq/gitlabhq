# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UrlHelpers, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  describe '.normalized_base_url' do
    where(:url, :value) do
      'http://' | nil
      'ssh://foo:bar@example.com' | 'ssh://example.com'
      'http://foo:bar@example.com:3000/dir' | 'http://example.com:3000'
      'http://foo:bar@example.com/dir' | 'http://example.com'
      'https://foo:bar@subdomain.example.com/dir' | 'https://subdomain.example.com'
    end

    with_them do
      it { expect(described_class.normalized_base_url(url)).to eq(value) }
    end
  end
end
