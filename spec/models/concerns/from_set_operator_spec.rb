# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FromSetOperator do
  describe 'when set operator method already exists' do
    let(:redefine_method) do
      Class.new do
        def self.from_union
          # This method intentionally left blank.
        end

        extend FromSetOperator
        define_set_operator Gitlab::SQL::Union
      end
    end

    it { expect { redefine_method }.to raise_exception(RuntimeError) }
  end
end
