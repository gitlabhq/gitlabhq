require 'spec_helper'

describe EventEntity do
  subject { described_class.represent(create(:event)).as_json }

  it 'exposes author' do
    expect(subject).to include(:author)
  end

  it 'exposes core elements of event' do
    expect(subject).to include(:updated_at)
  end
end
