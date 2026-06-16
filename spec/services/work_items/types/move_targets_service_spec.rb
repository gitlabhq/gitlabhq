# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Types::MoveTargetsService, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:source_group) { create(:group, developers: current_user) }
  let_it_be(:target_group) { create(:group, developers: current_user) }
  let_it_be(:source_project) { create(:project, group: source_group) }
  let_it_be(:target_project) { create(:project, group: target_group) }

  let(:provider) { WorkItems::TypesFramework::Provider.new(source_project.project_namespace) }
  let(:issue_type) { provider.find_by_base_type(:issue) }
  let(:task_type) { provider.find_by_base_type(:task) }
  let(:incident_type) { provider.find_by_base_type(:incident) }
  let(:ticket_type) { provider.find_by_base_type(:ticket) }

  subject(:finder) do
    described_class.new(
      current_user: current_user,
      source_namespace: source_project.project_namespace,
      target_namespace: target_project.project_namespace,
      source_type_ids: source_type_ids
    )
  end

  describe '#execute' do
    context 'with an empty source_type_ids' do
      let(:source_type_ids) { [] }

      it 'returns an empty array' do
        expect(finder.execute).to eq([])
      end
    end

    context 'with a blank target namespace' do
      let(:source_type_ids) { [issue_type.id] }

      subject(:finder) do
        described_class.new(
          current_user: current_user,
          source_namespace: source_project.project_namespace,
          target_namespace: nil,
          source_type_ids: source_type_ids
        )
      end

      it 'returns an empty array' do
        expect(finder.execute).to eq([])
      end
    end

    context 'when source type is not found' do
      let(:source_type_ids) { [-1] }

      it 'skips unknown source ids' do
        expect(finder.execute).to be_empty
      end
    end

    context 'when source type does not support move action' do
      let(:source_type_ids) { [task_type.id] }

      it 'returns an empty valid_target_types list and nil suggestion' do
        result = finder.execute.first

        expect(result.source_type).to eq(task_type)
        expect(result.suggested_target_type).to be_nil
        expect(result.valid_target_types).to be_empty
      end
    end

    context 'when source is system-defined Issue' do
      let(:source_type_ids) { [issue_type.id] }

      it 'suggests the destination Issue (gid match)', :aggregate_failures do
        result = finder.execute.first

        expect(result.source_type).to eq(issue_type)
        expect(result.suggested_target_type).to eq(issue_type)
        target_type_ids = result.valid_target_types.map(&:id)
        expect(target_type_ids).to include(issue_type.id)
      end

      it 'includes the source identity in valid_target_types so the item can stay as the same type' do
        result = finder.execute.first

        expect(result.valid_target_types.map(&:id)).to include(issue_type.id)
      end
    end

    context 'with multiple source type ids' do
      let(:source_type_ids) { [issue_type.id, task_type.id] }

      it 'returns one result per source type' do
        results = finder.execute

        expect(results.map(&:source_type)).to contain_exactly(issue_type, task_type)
      end

      it 'preserves order of source_type_ids input' do
        results = finder.execute

        expect(results.map { |r| r.source_type.id }).to eq([issue_type.id, task_type.id])
      end
    end

    context 'with duplicate source_type_ids' do
      let(:source_type_ids) { [issue_type.id, issue_type.id] }

      it 'de-duplicates and returns a single result', :aggregate_failures do
        results = finder.execute

        expect(results.size).to eq(1)
        expect(results.first.source_type).to eq(issue_type)
      end
    end
  end
end
