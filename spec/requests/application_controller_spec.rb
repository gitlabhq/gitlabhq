# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationController, type: :request, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it_behaves_like 'Base action controller' do
    subject(:request) { get root_path }
  end
end
