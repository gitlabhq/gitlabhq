# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ContentTypes, feature_category: :tooling do
  using RSpec::Parameterized::TableSyntax

  describe '.sanitize_content_type' do
    where(:content_type, :expected_content_type) do
      'application/gzip' | 'application/gzip'
      'text/javascript'  | described_class::DEFAULT_CONTENT_TYPE
      ''                 | described_class::DEFAULT_CONTENT_TYPE
      nil                | described_class::DEFAULT_CONTENT_TYPE
    end

    with_them do
      it 'sanitizes content types if it is safe' do
        res = described_class.sanitize_content_type(content_type)

        expect(res).to eq(expected_content_type)
      end
    end
  end
end
