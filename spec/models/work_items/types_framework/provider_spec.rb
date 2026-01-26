# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::Provider, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue_type) { create(:work_item_type, :issue) }
  let_it_be(:task_type) { create(:work_item_type, :task) }

  let(:provider) { described_class.new(project) }

  describe '#unfiltered_base_types' do
    subject { provider.unfiltered_base_types }

    it { is_expected.to match_array(WorkItems::Type.base_types.keys) }

    it { is_expected.to all(be_a(String)) }
  end

  describe '#filtered_types' do
    subject { provider.filtered_types }

    it { is_expected.to match_array(WorkItems::Type.all) }
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

  describe '#ids_by_base_types' do
    context 'with a single valid type' do
      it 'returns an array with the type ID' do
        result = provider.ids_by_base_types([:issue])

        expect(result).to be_an(Array)
        expect(result).to contain_exactly(WorkItems::Type::BASE_TYPES[:issue][:id])
      end
    end

    context 'with multiple valid types' do
      it 'returns an array with all type IDs' do
        result = provider.ids_by_base_types([:issue, :task, :incident])

        expected_ids = [
          WorkItems::Type::BASE_TYPES[:issue][:id],
          WorkItems::Type::BASE_TYPES[:task][:id],
          WorkItems::Type::BASE_TYPES[:incident][:id]
        ]

        expect(result).to match_array(expected_ids)
      end
    end

    context 'with string type names' do
      it 'converts strings to symbols and returns the IDs' do
        result = provider.ids_by_base_types(%w[issue task])

        expected_ids = [
          WorkItems::Type::BASE_TYPES[:issue][:id],
          WorkItems::Type::BASE_TYPES[:task][:id]
        ]

        expect(result).to match_array(expected_ids)
      end
    end

    context 'with invalid type names' do
      it 'filters out non-existent types and returns empty array' do
        result = provider.ids_by_base_types([:non_existent_type, :another_invalid])

        expect(result).to eq([])
      end
    end

    context 'with empty array' do
      it 'returns an empty array' do
        result = provider.ids_by_base_types([])

        expect(result).to eq([])
      end
    end

    context 'with nil input' do
      it 'returns an empty array' do
        result = provider.ids_by_base_types(nil)

        expect(result).to eq([])
      end
    end

    context 'with a single type as non-array' do
      it 'wraps the type in an array and returns the ID' do
        result = provider.ids_by_base_types(:issue)

        expect(result).to contain_exactly(WorkItems::Type::BASE_TYPES[:issue][:id])
      end
    end
  end

  describe '#type_exists?' do
    context 'with an existing type as string' do
      it 'returns true' do
        expect(provider.type_exists?('issue')).to be true
      end
    end

    context 'with an existing type as symbol' do
      it 'returns true' do
        expect(provider.type_exists?(:issue)).to be true
      end
    end

    context 'with a non-existent type' do
      it 'returns false' do
        expect(provider.type_exists?('non_existent_type')).to be false
      end
    end

    context 'with nil input' do
      it 'returns false' do
        expect(provider.type_exists?(nil)).to be false
      end
    end

    context 'with empty string' do
      it 'returns false' do
        expect(provider.type_exists?('')).to be false
      end
    end

    context 'with different case' do
      it 'is case-sensitive and returns false for incorrect case' do
        # Assuming base_types keys are lowercase symbols
        expect(provider.type_exists?('ISSUE')).to be false
      end
    end
  end

  describe '#default_issue_type' do
    subject { provider.default_issue_type }

    it { is_expected.to eq(issue_type) }
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

    context 'with existing id' do
      let(:id) { issue_type.id }

      it { is_expected.to eq(issue_type) }
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

  describe '#all_ordered_by_name' do
    subject(:result) { provider.all_ordered_by_name.map(&:name) }

    it 'returns types sorted by name' do
      expect(result).to eq(result.sort)
    end
  end

  describe '#by_ids_ordered_by_name' do
    subject { provider.by_ids_ordered_by_name(ids) }

    let(:ids) { [task_type.id, issue_type.id] }

    it { is_expected.to contain_exactly(task_type, issue_type) }
  end

  describe '#by_base_types_ordered_by_name' do
    subject { provider.by_base_types_ordered_by_name(names) }

    let(:names) { [:task, :issue] }

    it { is_expected.to contain_exactly(task_type, issue_type) }
  end
end
