require 'spec_helper'
require_relative '../../config/initializers/doorkeeper'

describe Doorkeeper.configuration do
  it 'default_scopes matches Gitlab::Auth::DEFAULT_SCOPES' do
    expect(subject.default_scopes).to eq Gitlab::Auth::DEFAULT_SCOPES
  end

  it 'optional_scopes matches Gitlab::Auth::OPTIONAL_SCOPES' do
    expect(subject.optional_scopes).to eq Gitlab::Auth::OPTIONAL_SCOPES
  end
end
