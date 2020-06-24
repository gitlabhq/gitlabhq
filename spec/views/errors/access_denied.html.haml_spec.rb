# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'errors/access_denied' do
  it 'does not fail to render when there is no message provided' do
    expect { render }.not_to raise_error
  end
end
