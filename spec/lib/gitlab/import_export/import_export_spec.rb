# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport do
  describe 'export filename' do
    let(:group) { build(:group, path: 'child', parent: build(:group, path: 'parent')) }
    let(:project) { build(:project, :public, path: 'project-path', namespace: group) }

    it 'contains the project path' do
      expect(described_class.export_filename(exportable: project)).to include(project.path)
    end

    it 'contains the namespace path' do
      expect(described_class.export_filename(exportable: project)).to include(project.namespace.full_path.tr('/', '_'))
    end

    it 'does not go over a certain length' do
      project.path = 'a' * 100

      expect(described_class.export_filename(exportable: project).length).to be < 70
    end
  end

  describe '#snippet_repo_bundle_filename_for' do
    let(:snippet) { build(:snippet, id: 1) }

    it 'generates the snippet bundle name' do
      expect(described_class.snippet_repo_bundle_filename_for(snippet)).to eq "#{snippet.hexdigest}.bundle"
    end
  end
end
