# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SQL::Intersect do
  it_behaves_like 'SQL set operator', 'INTERSECT'
end
