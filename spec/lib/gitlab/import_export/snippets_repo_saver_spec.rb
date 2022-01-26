# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::SnippetsRepoSaver do
  describe 'bundle a project Git repo' do
    let_it_be(:user) { create(:user) }

    let!(:project) { create(:project) }
    let(:shared) { project.import_export_shared }
    let(:bundler) { described_class.new(current_user: user, project: project, shared: shared) }

    after do
      FileUtils.rm_rf(shared.export_path)
    end

    it 'creates the snippet bundles dir if not exists' do
      snippets_dir = ::Gitlab::ImportExport.snippets_repo_bundle_path(shared.export_path)
      expect(Dir.exist?(snippets_dir)).to be_falsey

      bundler.save # rubocop:disable Rails/SaveBang

      expect(Dir.exist?(snippets_dir)).to be_truthy
    end

    context 'when project does not have any snippet' do
      it 'does not perform any action' do
        expect(Gitlab::ImportExport::SnippetRepoSaver).not_to receive(:new)

        bundler.save # rubocop:disable Rails/SaveBang
      end
    end

    context 'when project has snippets' do
      let!(:snippet1) { create(:project_snippet, :repository, project: project, author: user) }
      let!(:snippet2) { create(:project_snippet, project: project, author: user) }
      let(:service) { instance_double(Gitlab::ImportExport::SnippetRepoSaver) }

      it 'calls the SnippetRepoSaver for each snippet' do
        allow(Gitlab::ImportExport::SnippetRepoSaver).to receive(:new).and_return(service)
        expect(service).to receive(:save).and_return(true).twice

        bundler.save # rubocop:disable Rails/SaveBang
      end

      context 'when one snippet cannot be saved' do
        it 'returns false and do not process other snippets' do
          allow(Gitlab::ImportExport::SnippetRepoSaver).to receive(:new).with(hash_including(repository: snippet1.repository)).and_return(service)
          allow(service).to receive(:save).and_return(false)

          expect(Gitlab::ImportExport::SnippetRepoSaver).not_to receive(:new).with(hash_including(repository: snippet2.repository))
          expect(bundler.save).to be_falsey
        end
      end
    end
  end
end
