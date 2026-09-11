# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HasWiki, feature_category: :wiki do
  describe '#check_wiki_path_conflict' do
    let_it_be(:namespace) { create(:group) }

    context 'when a sibling project with the .wiki shadow path exists' do
      it 'flags the conflict', :aggregate_failures do
        create(:project, namespace: namespace, path: 'foo.wiki')
        project = build(:project, namespace: namespace, path: 'foo')

        expect(project).not_to be_valid
        expect(project.errors[:name]).to include('has already been taken')
      end
    end

    context 'when validating a project whose path already ends with .wiki' do
      it 'flags the conflict against a sibling project with the base path', :aggregate_failures do
        create(:project, namespace: namespace, path: 'foo')
        project = build(:project, namespace: namespace, path: 'foo.wiki')

        expect(project).not_to be_valid
        expect(project.errors[:name]).to include('has already been taken')
      end
    end

    context 'when a sibling group with the .wiki shadow path exists' do
      it 'flags the conflict', :aggregate_failures do
        create(:group, parent: namespace, path: 'foo.wiki')
        project = build(:project, namespace: namespace, path: 'foo')

        expect(project).not_to be_valid
        expect(project.errors[:name]).to include('has already been taken')
      end
    end

    context 'when the conflicting project lives under a different namespace' do
      it 'does not flag the conflict' do
        other_namespace = create(:group)
        create(:project, namespace: other_namespace, path: 'foo.wiki')
        project = build(:project, namespace: namespace, path: 'foo')

        expect(project).to be_valid
      end
    end

    context 'when the conflicting group lives under a different parent' do
      it 'does not flag the conflict' do
        other_namespace = create(:group)
        create(:group, parent: other_namespace, path: 'foo.wiki')
        project = build(:project, namespace: namespace, path: 'foo')

        expect(project).to be_valid
      end
    end

    context 'when there is no path conflict at all' do
      it 'is valid' do
        project = build(:project, namespace: namespace, path: 'foo')

        expect(project).to be_valid
      end
    end
  end
end
