require 'spec_helper'

describe Keys::DestroyService do
  let(:user) { create(:user) }

  subject { described_class.new(user) }

  it 'destroys a key' do
    key = create(:key)

    expect { subject.execute(key) }.to change(Key, :count).by(-1)
  end
end
