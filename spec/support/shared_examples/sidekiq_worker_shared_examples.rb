shared_examples 'sidekiq worker' do
  let(:queues) do
    YAML.load_file(Rails.root.join('config', 'sidekiq_queues.yml'))
      .fetch(:queues, []).map(&:first)
  end

  it 'is going to be processed inside a known sidekiq queue' do
    expect(described_class.sidekiq_options['queue']).to be_in queues
  end
end
