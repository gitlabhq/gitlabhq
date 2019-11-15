# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Cleanup::OrphanJobArtifactFiles do
  let(:null_logger) { Logger.new('/dev/null') }
  subject(:cleanup) { described_class.new(logger: null_logger) }

  before do
    allow(null_logger).to receive(:info)
  end

  it 'passes on dry_run' do
    expect(Gitlab::Cleanup::OrphanJobArtifactFilesBatch)
      .to receive(:new)
      .with(dry_run: false, batch_size: anything, logger: anything)
      .at_least(:once)
      .and_call_original

    described_class.new(dry_run: false).run!
  end

  it 'errors when invalid niceness is given' do
    allow(Gitlab::Utils).to receive(:which).with('ionice').and_return('/fake/ionice')
    cleanup = described_class.new(logger: null_logger, niceness: 'FooBar')

    expect { cleanup.run! }.to raise_error('Invalid niceness')
  end

  it 'finds artifacts on disk' do
    artifact = create(:ci_job_artifact, :archive)

    expect(cleanup).to receive(:find_artifacts).and_yield(artifact.file.path)
    cleanup.run!
  end

  it 'stops when limit is reached' do
    cleanup = described_class.new(limit: 1)

    mock_artifacts_found(cleanup, 'tmp/foo/bar/1', 'tmp/foo/bar/2')

    cleanup.run!

    expect(cleanup.total_found).to eq(1)
  end

  it 'cleans even if batch is not full' do
    mock_artifacts_found(cleanup, 'tmp/foo/bar/1')

    expect(cleanup).to receive(:clean_batch!).and_call_original
    cleanup.run!
  end

  it 'cleans in batches' do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
    mock_artifacts_found(cleanup, 'tmp/foo/bar/1', 'tmp/foo/bar/2', 'tmp/foo/bar/3')

    expect(cleanup).to receive(:clean_batch!).twice.and_call_original
    cleanup.run!
  end

  def mock_artifacts_found(cleanup, *files)
    mock = allow(cleanup).to receive(:find_artifacts)

    # Because we shell out to run `find -L ...`, each file actually
    # contains a trailing newline
    files.each { |file| mock.and_yield("#{file}\n") }
  end
end
