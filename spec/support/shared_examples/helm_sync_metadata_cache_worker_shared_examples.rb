# frozen_string_literal: true

RSpec.shared_examples 'does not enqueue a worker to sync a helm metadata cache' do
  it 'does not enqueue a worker to sync a helm metadata cache' do
    expect(Packages::Helm::CreateMetadataCacheWorker).not_to receive(:bulk_perform_async_with_contexts)

    execute
  end
end

RSpec.shared_examples 'enqueue a worker to sync a helm metadata cache' do
  before do
    project.add_maintainer(user)
  end

  it 'enqueues a worker to create a metadata cache' do
    expect(Packages::Helm::CreateMetadataCacheWorker)
      .to receive(:bulk_perform_async_with_contexts) do |metadata, arguments_proc:, context_proc:|
        expect(metadata.map(&:channel)).to match_array([channel])

        metadata.each do |metadatum|
          expect(arguments_proc.call(metadatum)).to eq([package.project_id, channel])
          expect(context_proc.call(metadatum)).to eq(project: package.project, user: user)
        end
      end

    execute
  end
end
