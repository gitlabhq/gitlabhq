# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RepoSaver do
  describe 'bundle a project Git repo' do
    let_it_be(:user) { create(:user) }

    let_it_be(:project) { create(:project, :small_repo, maintainers: user) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:bundler) { described_class.new(exportable: project, shared: shared) }

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(bundler.save).to be true
    end

    it 'creates the directory for the repository' do
      allow(bundler).to receive(:bundle_full_path).and_return('/foo/bar/file.tar.gz')

      expect(FileUtils).to receive(:mkdir_p).with('/foo/bar', anything)

      bundler.save # rubocop:disable Rails/SaveBang
    end

    context 'when the repo is empty' do
      let_it_be(:project) { create(:project, maintainers: user) }

      it 'bundles the repo successfully' do
        expect(bundler.save).to be true
      end
    end
  end
end
