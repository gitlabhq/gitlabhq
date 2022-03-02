# frozen_string_literal: true

RSpec.shared_examples 'invalidates attention request cache' do
  it 'invalidates the merge requests requiring attention count' do
    cache_mock = double

    users.each do |user|
      expect(cache_mock).to receive(:delete).with(['users', user.id, 'attention_requested_open_merge_requests_count'])
    end

    allow(Rails).to receive(:cache).and_return(cache_mock)

    service.execute
  end
end
