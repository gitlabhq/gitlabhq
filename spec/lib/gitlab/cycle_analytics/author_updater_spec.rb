require 'spec_helper'

describe Gitlab::CycleAnalytics::AuthorUpdater do
  let(:user) { create(:user) }
  let(:events) { [{ 'author_id' => user.id }] }

  it 'maps the correct user' do
    described_class.update!(events)

    expect(events.first['author']).to eq(user)
  end
end
