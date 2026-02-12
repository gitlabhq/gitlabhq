# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::Provider, feature_category: :team_planning do
  let_it_be(:namespace) { create(:namespace) }
  # TODO: change this to system defined in this MR:
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
  let_it_be(:issue_type) { build(:work_item_type, :issue) }
  let_it_be(:task_type) { build(:work_item_type, :task) }

  let(:provider) { described_class.new(namespace) }

  describe '.unfiltered_base_types' do
    it 'returns all base type keys from WorkItems::Type' do
      expected_types = WorkItems::Type.base_types.keys

      expect(described_class.unfiltered_base_types).to match_array(expected_types)
    end
  end

  describe '#initialize' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }

    context 'when namespace is provided' do
      it 'sets the namespace' do
        provider = described_class.new(namespace)

        expect(provider.namespace).to eq(namespace)
      end
    end

    context 'when namespace is not provided' do
      it 'sets namespace to nil' do
        provider = described_class.new

        expect(provider.namespace).to be_nil
      end
    end
  end

  describe '#fetch_work_item_type' do
    context "when work_item_system_defined_type is disabled" do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      context 'when given a WorkItems::Type object' do
        let_it_be(:issue_type) { create(:work_item_type, :issue) }

        it 'returns the work item type' do
          result = provider.fetch_work_item_type(issue_type)

          expect(result).to eq(issue_type)
        end
      end
    end

    context 'when given a WorkItems::Type object' do
      let_it_be(:issue_type_from_db) { create(:work_item_type, :issue) }

      it 'returns the work item type' do
        result = provider.fetch_work_item_type(issue_type_from_db)

        expect(result).to eq(issue_type)
      end
    end

    context 'when given a WorkItems::TypesFramework::SystemDefined::Type object' do
      it 'returns the work item type' do
        result = provider.fetch_work_item_type(issue_type)

        expect(result).to eq(issue_type)
      end
    end

    context 'when given an integer ID' do
      it 'returns the work item type by ID' do
        result = provider.fetch_work_item_type(issue_type.id)

        expect(result).to eq(issue_type)
      end
    end

    context 'when given an integer ID in a string format' do
      it 'returns the work item type by ID' do
        result = provider.fetch_work_item_type(issue_type.id.to_s)

        expect(result).to eq(issue_type)
      end
    end

    context 'when given nil' do
      it 'returns nil' do
        result = provider.fetch_work_item_type(nil)

        expect(result).to be_nil
      end
    end

    context 'when given a non-existent ID' do
      it 'returns nil' do
        result = provider.fetch_work_item_type(non_existing_record_id)

        expect(result).to be_nil
      end
    end
  end

  describe '#unfiltered_base_types' do
    subject { provider.unfiltered_base_types }

    # TODO: Uncomment this test in this MR
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
    # it { is_expected.to match_array(WorkItems::TypesFramework::SystemDefined::Type.all.map(&:base_type)) }

    it { is_expected.to all(be_a(String)) }

    context "when work_item_system_defined_type is disabled" do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it { is_expected.to match_array(WorkItems::Type.base_types.keys) }
    end
  end

  describe '#unfiltered_base_types_for_issue_type' do
    it 'converts base types to uppercase' do
      base_types = provider.unfiltered_base_types
      expected_types = base_types.map(&:upcase)

      result = provider.unfiltered_base_types_for_issue_type

      expect(result).to match_array(expected_types)
    end
  end

  describe '#type_exists?' do
    context 'when type exists' do
      it 'returns true for issue type' do
        expect(provider.type_exists?(:issue)).to be(true)
      end

      it 'returns true for task type' do
        expect(provider.type_exists?(:task)).to be(true)
      end

      it 'returns true for incident type' do
        expect(provider.type_exists?(:incident)).to be(true)
      end

      it 'accepts string argument' do
        expect(provider.type_exists?('issue')).to be(true)
      end
    end

    context 'when type does not exist' do
      it 'returns false for non-existent type' do
        expect(provider.type_exists?(:non_existent_type)).to be(false)
      end

      it 'returns false for empty string' do
        expect(provider.type_exists?('')).to be(false)
      end

      it 'returns false for nil' do
        expect(provider.type_exists?(nil)).to be(false)
      end
    end
  end

  describe '#find_by_base_type' do
    subject { provider.find_by_base_type(name) }

    context 'with existing base type' do
      let(:name) { :issue }

      it { is_expected.to eq(issue_type) }
    end

    context 'with non-existent base type' do
      let(:name) { :nonexistent }

      it { is_expected.to be_nil }
    end
  end

  describe "#find_by_name" do
    subject { provider.find_by_name(name) }

    context 'with existing name' do
      let(:name) { "Issue" }

      it { is_expected.to eq(issue_type) }
    end

    context 'with existing name as symbol' do
      let(:name) { :Issue }

      it { is_expected.to eq(issue_type) }
    end

    context "for case sensitivity" do
      let(:name) { "issue" }

      it { is_expected.to be_nil }
    end

    context 'with non-existent name' do
      let(:name) { "NonExistent" }

      it { is_expected.to be_nil }
    end
  end

  describe '#default_issue_type' do
    subject { provider.default_issue_type }

    it { is_expected.to eq(issue_type) }
  end

  describe '#filtered_types' do
    subject { provider.filtered_types }

    # TODO: Uncomment this test in this MR
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
    # it { is_expected.to match_array(WorkItems::TypesFramework::SystemDefined::Type.all) }

    context "when work_item_system_defined_type is disabled" do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it { is_expected.to match_array(WorkItems::Type.all) }
    end
  end

  describe '#by_base_types' do
    subject { provider.by_base_types(names) }

    context 'with single base type' do
      let(:names) { [:issue] }

      it { is_expected.to include(issue_type) }
      it { is_expected.not_to include(task_type) }
    end

    context 'with multiple base types' do
      let(:names) { [:issue, :task] }

      it { is_expected.to include(issue_type, task_type) }
    end

    context 'with non-existent base type' do
      let(:names) { [:nonexistent] }

      it { is_expected.to be_empty }
    end
  end

  describe '#ids_by_base_types' do
    it 'returns IDs from BASE_TYPES constant' do
      result = provider.ids_by_base_types([:issue, :task])

      expected_ids = [issue_type.id, task_type.id]

      expect(result).to match_array(expected_ids)
    end

    it 'accepts string base types' do
      result = provider.ids_by_base_types(['issue'])

      expected_id = issue_type.id

      expect(result).to eq([expected_id])
    end

    it 'filters out non-existent types' do
      result = provider.ids_by_base_types([:issue, :non_existent])

      expected_id = issue_type.id

      expect(result).to eq([expected_id])
    end

    it 'returns empty array for empty input' do
      result = provider.ids_by_base_types([])

      expect(result).to eq([])
    end

    it 'returns empty array for nil input' do
      result = provider.ids_by_base_types(nil)

      expect(result).to eq([])
    end

    context 'with a single type as non-array' do
      it 'wraps the type in an array and returns the ID' do
        result = provider.ids_by_base_types(:issue)

        expect(result).to contain_exactly(issue_type.id)
      end
    end

    context 'when work_item_system_defined_type is disabled' do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it 'returns IDs by querying the database' do
        result = provider.ids_by_base_types([:issue, :task])

        expect(result).to match_array([issue_type.id, task_type.id])
      end
    end
  end

  describe '#find_by_gid' do
    subject { provider.find_by_gid(gid) }

    context 'with valid gid' do
      let(:gid) { Gitlab::GlobalId.build(model_name: 'WorkItems::Type', id: issue_type.id) }

      it { is_expected.to eq(issue_type) }
    end

    context 'with nil gid' do
      let(:gid) { nil }

      it { is_expected.to be_nil }
    end

    context 'with non-existent gid' do
      let(:gid) { Gitlab::GlobalId.build(model_name: 'WorkItems::Type', id: 99999) }

      it { is_expected.to be_nil }
    end
  end

  describe '#find_by_id' do
    subject { provider.find_by_id(id) }

    context "when work_item_system_defined_type is disabled" do
      let(:issue_type) { create(:work_item_type, :issue) }

      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      context 'with existing id' do
        let(:id) { issue_type.id }

        it { is_expected.to eq(issue_type) }
      end
    end

    context 'with existing id' do
      let(:id) { issue_type.id }

      it { is_expected.to eq(issue_type) }
    end

    context 'when given a string ID' do
      let(:id) { issue_type.id.to_s }

      it { is_expected.to eq(issue_type) }
    end

    context "when given nil" do
      let(:id) { nil }

      it { is_expected.to be_nil }
    end

    context 'with non-existent id' do
      let(:id) { 99999 }

      it { is_expected.to be_nil }
    end
  end

  describe '#by_ids' do
    subject { provider.by_ids(ids) }

    context 'with existing ids' do
      let(:ids) { [issue_type.id, task_type.id] }

      it { is_expected.to match_array([issue_type, task_type]) }
    end

    context 'with partial existing ids' do
      let(:ids) { [issue_type.id, 99999] }

      it { is_expected.to contain_exactly(issue_type) }
    end

    context 'with non-existent ids' do
      let(:ids) { [99999, 99998] }

      it { is_expected.to be_empty }
    end
  end

  describe '#by_ids_with_widget_definition_preload' do
    # TODO: change this to system defined in this MR:
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
    let(:issue_type) { build(:work_item_type, :issue) }
    let(:task_type) { build(:work_item_type, :task) }

    it 'returns work item types without preloading' do
      ids = [issue_type.id, task_type.id]

      result = provider.by_ids_with_widget_definition_preload(ids)

      expect(result).to match_array([issue_type, task_type])
    end

    it 'does not calls with_widget_definition_preload' do
      ids = [issue_type.id]
      relation = WorkItems::TypesFramework::SystemDefined::Type.where(id: ids)

      allow(WorkItems::TypesFramework::SystemDefined::Type).to receive(:where).with(id: ids).and_return(relation)
      expect(relation).not_to receive(:with_widget_definition_preload).and_call_original

      provider.by_ids_with_widget_definition_preload(ids)
    end

    context 'when work_item_system_defined_type is disabled' do
      let(:issue_type) { create(:work_item_type, :issue) }
      let(:task_type) { create(:work_item_type, :task) }

      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it 'returns work item types with widget definitions preloaded' do
        ids = [issue_type.id, task_type.id]

        result = provider.by_ids_with_widget_definition_preload(ids)

        expect(result).to match_array([issue_type, task_type])
      end

      it 'calls with_widget_definition_preload on the relation' do
        ids = [issue_type.id]
        relation = WorkItems::Type.where(id: ids)

        allow(WorkItems::Type).to receive(:where).with(id: ids).and_return(relation)
        expect(relation).to receive(:with_widget_definition_preload).and_call_original

        provider.by_ids_with_widget_definition_preload(ids)
      end
    end
  end

  describe '#base_types_by_ids' do
    let_it_be(:incident_type) { create(:work_item_type, :incident) }
    let_it_be(:another_issue_type) { create(:work_item_type, :issue) }

    context 'when given multiple IDs with different base types' do
      it 'returns unique base types' do
        ids = [issue_type.id, task_type.id, incident_type.id]

        result = provider.base_types_by_ids(ids)

        expect(result).to match_array(%w[issue task incident])
      end
    end

    context 'when given IDs with duplicate base types' do
      it 'returns unique base types only' do
        ids = [issue_type.id, another_issue_type.id, task_type.id]

        result = provider.base_types_by_ids(ids)

        expect(result).to match_array(%w[issue task])
      end
    end

    context 'when given a single ID' do
      it 'returns the base type in an array' do
        result = provider.base_types_by_ids([issue_type.id])

        expect(result).to eq(['issue'])
      end
    end

    context 'when given empty array' do
      it 'returns empty array' do
        result = provider.base_types_by_ids([])

        expect(result).to eq([])
      end
    end

    context 'when some IDs do not exist' do
      it 'returns base types for existing IDs only' do
        ids = [issue_type.id, non_existing_record_id, task_type.id]

        result = provider.base_types_by_ids(ids)

        expect(result).to match_array(%w[issue task])
      end
    end
  end

  describe '#all_ordered_by_name' do
    subject(:result) { provider.all_ordered_by_name.map(&:name) }

    it 'returns types sorted by name' do
      expect(result).to eq(result.sort)
    end
  end

  describe '#by_ids_ordered_by_name' do
    subject { provider.by_ids_ordered_by_name(ids) }

    let(:ids) { [task_type.id, issue_type.id] }

    # TODO: Remove stubbing the FF once we are able to assign SystemDefined Type as work_item_type to issue
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
    before do
      stub_feature_flags(work_item_system_defined_type: false)
    end

    it { is_expected.to contain_exactly(task_type, issue_type) }
  end

  describe '#by_base_types_ordered_by_name' do
    subject { provider.by_base_types_ordered_by_name(names) }

    let(:names) { [:task, :issue] }

    # TODO: Remove stubbing the FF once we are able to assign SystemDefined Type as work_item_type to issue
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
    before do
      stub_feature_flags(work_item_system_defined_type: false)
    end

    it { is_expected.to contain_exactly(task_type, issue_type) }
  end

  describe 'feature flag behavior' do
    describe '#use_system_defined_types?' do
      context 'when work_item_system_defined_type is enabled' do
        it 'returns true' do
          expect(provider.send(:use_system_defined_types?)).to be(true)
        end
      end

      context 'when work_item_system_defined_type is disabled' do
        before do
          stub_feature_flags(work_item_system_defined_type: false)
        end

        it 'returns false' do
          expect(provider.send(:use_system_defined_types?)).to be(false)
        end
      end
    end

    describe '#type_class' do
      # TODO: Add the case for system defined on this MR:
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
      it 'returns WorkItems::Type class' do
        expect(provider.send(:type_class)).to eq(WorkItems::Type)
      end
    end
  end
end
