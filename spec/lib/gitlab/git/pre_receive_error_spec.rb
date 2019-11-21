# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git::PreReceiveError do
  Gitlab::Git::PreReceiveError::SAFE_MESSAGE_PREFIXES.each do |prefix|
    context "error messages prefixed with #{prefix}" do
      it 'accepts only errors lines with the prefix' do
        ex = described_class.new("#{prefix} Hello,\nworld!")

        expect(ex.message).to eq('Hello,')
      end

      it 'makes its message HTML-friendly' do
        ex = described_class.new("#{prefix} Hello,\n#{prefix} world!\n")

        expect(ex.message).to eq('Hello,<br>world!')
      end
    end
  end
end
