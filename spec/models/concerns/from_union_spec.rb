# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FromUnion do
  it_behaves_like 'from set operator', Gitlab::SQL::Union
end
