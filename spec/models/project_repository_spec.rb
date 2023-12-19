# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectRepository, feature_category: :source_code_management do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'shardable scopes' do
    let_it_be(:record_1) { create(:project_repository) }
    let_it_be(:record_2, reload: true) { create(:project_repository) }
  end

  describe '.find_project' do
    it 'finds project by disk path' do
      project = create(:project)
      project.track_project_repository

      expect(described_class.find_project(project.disk_path)).to eq(project)
    end

    it 'returns nil when it does not find the project' do
      expect(described_class.find_project('@@unexisting/path/to/project')).to be_nil
    end
  end

  describe '#object_format' do
    subject { project_repository.object_format }

    let(:project_repository) { build(:project_repository, object_format: object_format) }

    context 'when object format is sha1' do
      let(:object_format) { 'sha1' }

      it { is_expected.to eq 'sha1' }
    end

    context 'when object format is sha256' do
      let(:object_format) { 'sha256' }

      it { is_expected.to eq 'sha256' }
    end

    context 'when object format is not set' do
      let(:project_repository) { build(:project_repository) }

      it { is_expected.to eq 'sha1' }
    end
  end
end
