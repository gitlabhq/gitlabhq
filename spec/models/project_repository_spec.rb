# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectRepository do
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
end
