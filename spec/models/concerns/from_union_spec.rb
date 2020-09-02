# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FromUnion do
  [true, false].each do |sql_set_operator|
    context "when sql-set-operators feature flag is #{sql_set_operator}" do
      before do
        stub_feature_flags(sql_set_operators: sql_set_operator)
      end

      it_behaves_like 'from set operator', Gitlab::SQL::Union
    end
  end
end
