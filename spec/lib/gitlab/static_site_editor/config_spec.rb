# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::StaticSiteEditor::Config do
  subject(:config) { described_class.new(repository, ref, file_path, return_url) }

  let(:project) { create(:project, :public, :repository, name: 'project', namespace: namespace) }
  let(:namespace) { create(:namespace, name: 'namespace') }
  let(:repository) { project.repository }
  let(:ref) { 'master' }
  let(:file_path) { 'README.md' }
  let(:return_url) { 'http://example.com' }

  describe '#payload' do
    subject { config.payload }

    it 'returns data for the frontend component' do
      is_expected.to eq(
        branch: 'master',
        commit: repository.commit.id,
        namespace: 'namespace',
        path: 'README.md',
        project: 'project',
        project_id: project.id,
        return_url: 'http://example.com'
      )
    end
  end
end
