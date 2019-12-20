# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git::RemoteMirror do
  describe '#update' do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository }
    let(:ref_name) { 'foo' }
    let(:options) { { only_branches_matching: ['master'], ssh_key: 'KEY', known_hosts: 'KNOWN HOSTS' } }

    subject(:remote_mirror) { described_class.new(repository, ref_name, **options) }

    it 'delegates to the Gitaly client' do
      expect(repository.gitaly_remote_client)
        .to receive(:update_remote_mirror)
        .with(ref_name, ['master'], ssh_key: 'KEY', known_hosts: 'KNOWN HOSTS')

      remote_mirror.update
    end

    it 'wraps gitaly errors' do
      expect(repository.gitaly_remote_client)
        .to receive(:update_remote_mirror)
        .and_raise(StandardError)

      expect { remote_mirror.update }.to raise_error(StandardError)
    end
  end
end
