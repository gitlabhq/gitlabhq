# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::FullPathModelLoader, feature_category: :shared do
  include RepoHelpers

  describe '#find' do
    let_it_be(:group) { create(:group, path: 'test-group') }
    let_it_be(:project) { create(:project, namespace: group, path: 'test-project') }

    context 'when looking for a group' do
      it 'finds a group' do
        result = described_class.new(Group, 'test-group').find
        expect(result.sync).to eq(group)
      end

      context 'when passed in path matches a project instead' do
        it 'returns nothing' do
          result = described_class.new(Group, 'test-group/test-project').find
          expect(result.sync).to be_nil
        end
      end
    end

    context 'when looking for a project' do
      it 'finds a project' do
        result = described_class.new(Project, 'test-group/test-project').find
        expect(result.sync).to eq(project)
      end

      context 'when passed in path matches a group instead' do
        it 'returns nothing' do
          result = described_class.new(Project, 'test-group').find
          expect(result.sync).to be_nil
        end
      end
    end

    context 'when looking for a Namespace' do
      it 'finds a project' do
        result = described_class.new(Namespace, 'test-group/test-project').find
        expect(result.sync).to eq(project.project_namespace)
      end

      it 'finds a group' do
        result = described_class.new(Namespace, 'test-group').find
        expect(result.sync).to eq(group)
      end
    end

    context 'when a returned model matches the requested full_path' do
      it 'does not log an error' do
        expect(Gitlab::AppLogger).not_to receive(:error)

        result = described_class.new(Namespace, 'test-group/test-project').find

        expect(result.sync).to eq(project.project_namespace)
      end
    end

    context 'when a returned model does not match a requested full_path' do
      it 'logs an error and still loads the model under its computed full_path', :aggregate_failures do
        allow(Group).to receive(:where_full_path_in).and_return([group])

        expect(Gitlab::AppLogger).to receive(:error).with(
          message: 'FullPathModelLoader computed full_path did not match a requested key',
          class: 'Gitlab::Graphql::Loaders::FullPathModelLoader',
          model_class: 'Group',
          model_id: group.id,
          computed_full_path: group.full_path.downcase
        )

        result = described_class.new(Group, 'nonexistent-group').find

        expect(result.sync).to be_nil
      end
    end

    it 'only queries once' do
      expect do
        [
          described_class.new(Project, 'test-group/test-project').find,
          described_class.new(Group, 'test-group').find,
          described_class.new(Project, 'test-group/test-project').find,
          described_class.new(Group, 'test-group').find,
          described_class.new(Project, 'test-group/test-project').find
        ].map(&:sync)
      end.not_to exceed_query_limit(4) # 1 for project, 1 for group and one to load routes for each
    end
  end
end
