# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsFileLockEntity do
  let(:user)     { create(:user) }
  let(:resource) { create(:lfs_file_lock, user: user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'exposes basic attrs of the lock' do
    expect(subject).to include(:id, :path, :locked_at)
  end

  it 'exposes the owner info' do
    expect(subject).to include(:owner)
    expect(subject[:owner][:name]).to eq(user.username)
  end
end
