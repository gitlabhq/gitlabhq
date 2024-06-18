# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ReplicateService, feature_category: :source_code_management do
  let(:new_checksum) { 'match' }
  let(:repository) { instance_double('Gitlab::Git::Repository', checksum: 'match') }
  let(:new_repository) { instance_double('Gitlab::Git::Repository', checksum: new_checksum) }

  subject { described_class.new(repository) }

  it 'replicates repository' do
    expect(new_repository).to receive(:replicate).with(repository, partition_hint: "")
    expect(new_repository).not_to receive(:remove)

    expect { subject.execute(new_repository, :project) }.not_to raise_error
  end

  it 'replicates repository with partition_hint' do
    expect(new_repository).to receive(:replicate).with(repository, partition_hint: "partition_hint_path")
    expect(new_repository).not_to receive(:remove)

    expect { subject.execute(new_repository, :project, partition_hint: "partition_hint_path") }.not_to raise_error
  end

  context 'when checksum does not match' do
    let(:new_checksum) { 'does not match' }

    it 'raises an error and removes new repository' do
      expect(new_repository).to receive(:replicate).with(repository, partition_hint: "")
      expect(new_repository).to receive(:remove)

      expect do
        subject.execute(new_repository, :project)
      end.to raise_error(described_class::Error, /Failed to verify project repository/)
    end
  end

  context 'when an error is raised during checksum calculation' do
    it 'raises the error and removes new repository' do
      error = StandardError.new

      expect(new_repository).to receive(:replicate).with(repository, partition_hint: "")
      expect(new_repository).to receive(:checksum).and_raise(error)
      expect(new_repository).to receive(:remove)

      expect do
        subject.execute(new_repository, :project)
      end.to raise_error(error)
    end
  end
end
