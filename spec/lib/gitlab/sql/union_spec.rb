# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SQL::Union, feature_category: :shared do
  it_behaves_like 'SQL set operator', 'UNION'
end
