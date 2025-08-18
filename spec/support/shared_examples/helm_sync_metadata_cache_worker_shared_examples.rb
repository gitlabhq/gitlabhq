# frozen_string_literal: true

RSpec.shared_examples 'does not enqueue a worker to sync a helm metadata cache' do
  it 'does not enqueue a worker to sync a helm metadata cache' do
    expect(Packages::Helm::CreateMetadataCacheWorker).not_to receive(:perform_async)

    execute
  end
end

RSpec.shared_examples 'enqueue a worker to sync a helm metadata cache' do
  before do
    project.add_maintainer(user)
  end

  it 'enqueues a worker to create a metadata cache' do
    expect(Packages::Helm::CreateMetadataCacheWorker)
      .to receive(:perform_async).with(project.id, channel)

    execute
  end
end
