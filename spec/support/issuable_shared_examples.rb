shared_examples 'cache counters invalidator' do
  it 'invalidates counter cache for assignees' do
    expect_any_instance_of(User).to receive(:invalidate_merge_request_cache_counts)

    described_class.new(project, user, {}).execute(merge_request)
  end
end
