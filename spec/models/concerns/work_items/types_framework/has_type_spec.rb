# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::HasType, feature_category: :team_planning do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:system_defined_type) { build(:work_item_system_defined_type, :issue) }

  before do
    stub_const('TestWorkItem', Class.new(ApplicationRecord) do
      self.table_name = 'issues'
      include WorkItems::TypesFramework::HasType

      attr_accessor :namespace

      def initialize(attributes = {})
        @namespace = attributes.delete(:namespace)
        super
      end
    end)
  end

  subject(:work_item) { TestWorkItem.new(namespace: namespace) }

  describe 'included modules' do
    it { expect(described_class).to include(Gitlab::Utils::StrongMemoize) }
  end

  describe '#work_item_type' do
    before do
      work_item.work_item_type_id = system_defined_type.id
    end

    it 'returns the system_defined_type from the provider' do
      expect(work_item.work_item_type).to eq(system_defined_type)
    end

    context 'when work_item_type_id is nil' do
      before do
        work_item.work_item_type_id = nil
      end

      it 'returns nil' do
        expect(work_item.work_item_type).to be_nil
      end
    end
  end

  describe '#icon_name' do
    context 'when work_item_type is present' do
      before do
        work_item.work_item_type_id = system_defined_type.id
      end

      it 'delegates to work_item_type' do
        expect(work_item.icon_name).to eq(system_defined_type.icon_name)
      end
    end

    context 'when work_item_type is nil' do
      before do
        work_item.work_item_type_id = nil
      end

      it 'returns nil' do
        expect(work_item.icon_name).to be_nil
      end
    end
  end

  describe '#exported_work_item_type' do
    context 'when work_item_type is a system-defined type' do
      before do
        work_item.work_item_type_id = system_defined_type.id
      end

      it 'returns a hash with the type name' do
        expect(work_item.exported_work_item_type).to eq({ 'name' => system_defined_type.name })
      end

      context 'when work_item_configurable_types feature flag is disabled' do
        before do
          stub_feature_flags(work_item_configurable_types: false)
        end

        it 'returns a hash with the base_type for backward compatibility' do
          expect(work_item.exported_work_item_type).to eq({ 'base_type' => system_defined_type.base_type })
        end
      end
    end

    context 'when work_item_type cannot be resolved' do
      before do
        work_item.work_item_type_id = non_existing_record_id
      end

      it 'defaults to the issue type name' do
        issue_type = ::WorkItems::TypesFramework::Provider.new.default_issue_type

        expect(work_item.exported_work_item_type).to eq({ 'name' => issue_type.name })
      end

      context 'when work_item_configurable_types feature flag is disabled' do
        before do
          stub_feature_flags(work_item_configurable_types: false)
        end

        it 'defaults to the issue base_type' do
          expect(work_item.exported_work_item_type).to eq({ 'base_type' => 'issue' })
        end
      end
    end
  end

  describe '#work_item_type=' do
    context 'when we set a system_defined_type' do
      it 'sets the work_item_type_id' do
        expect { work_item.work_item_type = system_defined_type }
          .to change { work_item.work_item_type_id }
          .from(nil)
          .to(system_defined_type.id)
      end
    end

    context 'when we set to nil' do
      before do
        work_item.work_item_type_id = system_defined_type.id
      end

      it 'sets the work_item_type_id to nil' do
        expect { work_item.work_item_type = nil }
          .to change { work_item.work_item_type_id }
          .from(system_defined_type.id)
          .to(nil)
      end
    end

    context 'when we set with an id' do
      it 'sets the work_item_type_id' do
        expect { work_item.work_item_type = system_defined_type.id }
          .to change { work_item.work_item_type_id }
          .from(nil)
          .to(system_defined_type.id)
      end
    end
  end
end
