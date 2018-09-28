require 'spec_helper'

describe Gitlab::Git::PreReceiveError do
  it 'makes its message HTML-friendly' do
    ex = described_class.new("hello\nworld\n")

    expect(ex.message).to eq('hello<br>world<br>')
  end
end
