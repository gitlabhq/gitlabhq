# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::SnippetRepoSaver do
  describe 'bundle a project Git repo' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: user.namespace) }
    let_it_be(:snippet) { create(:project_snippet, :repository, project: project, author: user) }

    let(:shared) { project.import_export_shared }
    let(:bundler) { described_class.new(project: project, shared: shared, repository: snippet.repository) }
    let(:bundle_path) { ::Gitlab::ImportExport.snippets_repo_bundle_path(shared.export_path) }

    around do |example|
      FileUtils.mkdir_p(bundle_path)
      example.run
    ensure
      FileUtils.rm_rf(bundle_path)
    end

    context 'with project snippet' do
      it 'bundles the repo successfully' do
        aggregate_failures do
          expect(bundler.save).to be_truthy
          expect(Dir.empty?(bundle_path)).to be_falsey
        end
      end

      context 'when snippet does not have a repository' do
        let(:snippet) { build(:personal_snippet) }

        it 'returns true' do
          expect(bundler.save).to be_truthy
        end

        it 'does not create any file' do
          aggregate_failures do
            expect(snippet.repository).not_to receive(:bundle_to_disk)

            bundler.save # rubocop:disable Rails/SaveBang

            expect(Dir.empty?(bundle_path)).to be_truthy
          end
        end
      end
    end
  end
end
