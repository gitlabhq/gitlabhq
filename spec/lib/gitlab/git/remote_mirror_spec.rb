# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::RemoteMirror do
  describe '#update' do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository }
    let(:ref_name) { 'foo' }
    let(:url) { 'https://example.com' }
    let(:options) { { only_branches_matching: ['master'], ssh_key: 'KEY', known_hosts: 'KNOWN HOSTS', keep_divergent_refs: true } }

    subject(:remote_mirror) { described_class.new(repository, ref_name, url, **options) }

    shared_examples 'an update' do
      it 'delegates to the Gitaly client' do
        expect(repository.gitaly_remote_client)
          .to receive(:update_remote_mirror)
          .with(ref_name, url, ['master'], ssh_key: 'KEY', known_hosts: 'KNOWN HOSTS', keep_divergent_refs: true)

        remote_mirror.update # rubocop:disable Rails/SaveBang
      end
    end

    context 'with url' do
      it_behaves_like 'an update'
    end

    context 'without url' do
      let(:url) { nil }

      it_behaves_like 'an update'
    end

    it 'wraps gitaly errors' do
      expect(repository.gitaly_remote_client)
        .to receive(:update_remote_mirror)
        .and_raise(StandardError)

      expect { remote_mirror.update }.to raise_error(StandardError) # rubocop:disable Rails/SaveBang
    end
  end
end
