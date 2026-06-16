# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Helpers::Packages::ErrorMessage, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let(:helper) { Class.new { include API::Helpers::Packages::ErrorMessage }.new }

  describe '#error_message_detail' do
    where(:message, :expected_detail) do
      '403 Forbidden - Package protected.'  | 'Package protected.'
      '400 Bad request - File is too large' | 'File is too large'
      '400 Bad request - a - b - c'         | 'a - b - c'
      '403 Forbidden'                       | nil
      '404 Package Not Found'               | nil
      '404 Not Found'                       | nil
      'Validation failed: Name is invalid'  | nil
      'forbidden'                           | nil
      ''                                    | nil
      nil                                   | nil
      123                                   | nil
    end

    with_them do
      it { expect(helper.error_message_detail(message)).to eq(expected_detail) }
    end
  end

  describe '#error_message_single_line' do
    where(:value, :expected) do
      "line1\r\nline2" | 'line1  line2'
      "a\nb"           | 'a b'
      "a\rb"           | 'a b'
      "a\x00b"         | "a\x00b" # only CR/LF are collapsed; other control bytes pass through
      'café'           | 'café'   # non-ASCII is preserved
      'plain'          | 'plain'
      nil              | ''
    end

    with_them do
      it { expect(helper.error_message_single_line(value)).to eq(expected) }
    end
  end
end
