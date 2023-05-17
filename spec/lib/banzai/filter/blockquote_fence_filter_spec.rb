# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::BlockquoteFenceFilter, feature_category: :team_planning do
  include FilterSpecHelper

  it 'converts blockquote fences to blockquote lines', :unlimited_max_formatted_output_length do
    content = File.read(Rails.root.join('spec/fixtures/blockquote_fence_before.md'))
    expected = File.read(Rails.root.join('spec/fixtures/blockquote_fence_after.md'))

    output = filter(content)

    expect(output).to eq(expected)
  end

  it 'does not require newlines at start or end of string' do
    expect(filter(">>>\ntest\n>>>")).to eq("\n> test\n")
  end

  it 'allows trailing whitespace on blockquote fence lines' do
    expect(filter(">>> \ntest\n>>> ")).to eq("\n> test\n")
  end

  context 'when incomplete blockquote fences with multiple blocks are present' do
    it 'does not raise timeout error' do
      test_string = ">>>#{"\n```\nfoo\n```" * 20}"

      expect do
        Timeout.timeout(2.seconds) { filter(test_string) }
      end.not_to raise_error
    end
  end

  it_behaves_like 'text filter timeout' do
    let(:text) { ">>>\ntest\n>>>" }
  end
end
