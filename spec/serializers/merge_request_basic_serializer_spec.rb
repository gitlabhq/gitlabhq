require 'spec_helper'

describe MergeRequestBasicSerializer do
  let(:resource) { create(:merge_request) }
  let(:user)     { create(:user) }

  subject { described_class.new.represent(resource) }

  it 'has important MergeRequest attributes' do
    expect(subject).to include(:merge_status)
  end
end
