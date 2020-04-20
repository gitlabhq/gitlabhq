# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestBasicEntity do
  let(:resource) { build(:merge_request) }

  subject do
    described_class.new(resource).as_json
  end

  it 'has public_merge_status as merge_status' do
    expect(resource).to receive(:public_merge_status).and_return('checking')

    expect(subject[:merge_status]).to eq 'checking'
  end
end
