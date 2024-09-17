# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../spec/support/matchers/result_matchers'

RSpec.describe 'result matchers', feature_category: :workspaces do
  include ResultMatchers

  it 'works with value asserted via argument' do
    expect(Gitlab::Fp::Result.ok(1)).to be_ok_result(1)
    expect(Gitlab::Fp::Result.ok(1)).not_to be_ok_result(2)
    expect(Gitlab::Fp::Result.ok(1)).not_to be_err_result(1)
  end

  it 'works with value asserted via block' do
    expect(Gitlab::Fp::Result.err('hello')).to be_err_result do |result_value|
      expect(result_value).to match(/hello/i)
    end
  end
end
