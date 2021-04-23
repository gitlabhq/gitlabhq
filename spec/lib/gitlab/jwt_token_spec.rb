# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::JWTToken do
  it_behaves_like 'a gitlab jwt token'
end
