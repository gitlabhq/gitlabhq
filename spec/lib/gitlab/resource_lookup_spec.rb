# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ResourceLookup, feature_category: :api do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:looker_upper) do
    Class.new do
      include Gitlab::ResourceLookup

      def project_by(id, **kwargs)
        lookup_project(id, **kwargs)
      end

      def group_by(id, **kwargs)
        lookup_group(id, **kwargs)
      end
    end.new
  end

  describe '#lookup_project' do
    it 'finds a project by ID' do
      expect(looker_upper.project_by(project.id)).to eq(project)
    end

    it 'finds a project by full path' do
      expect(looker_upper.project_by(project.full_path)).to eq(project)
    end

    it 'follows a redirect from a previous path' do
      renamed = create(:project)
      old_path = renamed.full_path
      renamed.update!(path: 'renamed')

      expect(looker_upper.project_by(old_path)).to eq(renamed)
    end

    it 'returns nil when the ID is missing' do
      expect(looker_upper.project_by(nil)).to be_nil
    end

    it 'does not query by path when the argument has no slash' do
      expect(Project).not_to receive(:find_by_full_path)

      expect(looker_upper.project_by('undefined')).to be_nil
    end

    it 'excludes projects that are pending delete or hidden', :aggregate_failures do
      expect(looker_upper.project_by(create(:project, pending_delete: true).id)).to be_nil
      expect(looker_upper.project_by(create(:project, :hidden).id)).to be_nil
    end

    it 'honours a caller supplied scope' do
      expect(looker_upper.project_by(project.id, scope: Project.id_not_in(project.id))).to be_nil
    end
  end

  describe '#lookup_group' do
    it 'finds a group by ID' do
      expect(looker_upper.group_by(group.id)).to eq(group)
    end

    it 'finds a group by full path' do
      expect(looker_upper.group_by(group.full_path)).to eq(group)
    end

    it 'returns nil when nothing matches' do
      expect(looker_upper.group_by('does-not-exist')).to be_nil
    end

    it 'honours a caller supplied scope' do
      expect(looker_upper.group_by(group.id, scope: Group.id_not_in(group.id))).to be_nil
    end
  end
end
