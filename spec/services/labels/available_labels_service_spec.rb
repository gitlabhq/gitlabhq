# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Labels::AvailableLabelsService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, group: group) }
  let(:group) { create(:group) }

  let(:project_label) { create(:label, project: project) }
  let(:other_project_label) { create(:label) }
  let(:group_label) { create(:group_label, group: group) }
  let(:other_group_label) { create(:group_label) }
  let!(:labels) { [project_label, other_project_label, group_label, other_group_label] }

  describe '#find_or_create_by_titles' do
    let(:label_titles) { labels.map(&:title).push('non existing title') }

    context 'when parent is a project' do
      context 'when a user is not a project member' do
        it 'returns only relevant label ids' do
          result = described_class.new(user, project, labels: label_titles).find_or_create_by_titles

          expect(result).to match_array([project_label, group_label])
        end
      end

      context 'when a user is a project member' do
        before do
          project.add_developer(user)
        end

        it 'creates new labels for not found titles' do
          result = described_class.new(user, project, labels: label_titles).find_or_create_by_titles

          expect(result.count).to eq(5)
          expect(result).to include(project_label, group_label)
          expect(result).not_to include(other_project_label, other_group_label)
        end

        it 'do not cause additional query for finding labels' do
          label_titles = [project_label.title]
          control_count = ActiveRecord::QueryRecorder.new { described_class.new(user, project, labels: label_titles).find_or_create_by_titles }

          new_label = create(:label, project: project)
          label_titles = [project_label.title, new_label.title]
          expect { described_class.new(user, project, labels: label_titles).find_or_create_by_titles }.not_to exceed_query_limit(control_count)
        end
      end
    end

    context 'when parent is a group' do
      context 'when a user is not a group member' do
        it 'returns only relevant label ids' do
          result = described_class.new(user, group, labels: label_titles).find_or_create_by_titles

          expect(result).to match_array([group_label])
        end
      end

      context 'when a user is a group member' do
        before do
          group.add_developer(user)
        end

        it 'creates new labels for not found titles' do
          result = described_class.new(user, group, labels: label_titles).find_or_create_by_titles

          expect(result.count).to eq(5)
          expect(result).to include(group_label)
          expect(result).not_to include(project_label, other_project_label, other_group_label)
        end
      end
    end
  end

  describe '#filter_labels_ids_in_param' do
    let(:label_ids) { labels.map(&:id).push(non_existing_record_id) }

    context 'when parent is a project' do
      it 'returns only relevant label ids' do
        result = described_class.new(user, project, ids: label_ids).filter_labels_ids_in_param(:ids)

        expect(result).to match_array([project_label.id, group_label.id])
      end

      it 'returns labels in preserved order' do
        result = described_class.new(user, project, ids: label_ids.reverse).filter_labels_ids_in_param(:ids)

        expect(result).to eq([group_label.id, project_label.id])
      end
    end

    context 'when parent is a group' do
      it 'returns only relevant label ids' do
        result = described_class.new(user, group, ids: label_ids).filter_labels_ids_in_param(:ids)

        expect(result).to match_array([group_label.id])
      end
    end

    it 'accepts a single id parameter' do
      result = described_class.new(user, project, label_id: project_label.id).filter_labels_ids_in_param(:label_id)

      expect(result).to match_array([project_label.id])
    end
  end

  describe '#available_labels' do
    context 'when parent is a project' do
      it 'returns only relevant labels' do
        result = described_class.new(user, project, {}).available_labels

        expect(result.count).to eq(2)
        expect(result).to include(project_label, group_label)
        expect(result).not_to include(other_project_label, other_group_label)
      end
    end

    context 'when parent is a group' do
      it 'returns only relevant labels' do
        result = described_class.new(user, group, {}).available_labels

        expect(result.count).to eq(1)
        expect(result).to include(group_label)
        expect(result).not_to include(project_label, other_project_label, other_group_label)
      end
    end
  end
end
