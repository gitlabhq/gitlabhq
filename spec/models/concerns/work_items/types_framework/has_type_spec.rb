# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::HasType, feature_category: :team_planning do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:work_item_type) { create(:work_item_type, namespace: namespace) }
  let_it_be(:system_defined_type) { build(:work_item_system_defined_type, :issue) }

  before do
    stub_const('TestWorkItem', Class.new(ApplicationRecord) do
      self.table_name = 'issues'
      include WorkItems::TypesFramework::HasType

      attr_accessor :namespace

      # Simulate the typical ActiveRecord belongs_to association
      belongs_to :work_item_type, class_name: 'WorkItems::Type'

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
      # TODO change that to expect work_item.work_item_type to eq system_defined_type once we
      # integrate the system defined types into the types provider
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
      expect(work_item.work_item_type_id).to eq(system_defined_type.id)
    end

    context 'when work_item_type_id is nil' do
      before do
        work_item.work_item_type_id = nil
      end

      it 'returns nil' do
        expect(work_item.work_item_type).to be_nil
      end
    end

    context "when the FF for system defined types is disabled" do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it 'returns the work_item_type from the provider' do
        expect(work_item.work_item_type).to eq(work_item_type)
      end

      it 'calls super' do
        expect(work_item).to receive(:work_item_type).and_call_original

        work_item.work_item_type
      end
    end
  end

  describe '#work_item_type=' do
    context 'when we set a db work_item_type' do
      it 'sets the work_item_type_id' do
        expect { work_item.work_item_type = work_item_type }
          .to change { work_item.work_item_type_id }
          .from(nil)
          .to(system_defined_type.id)
      end

      it 'does not use the belongs_to setter' do
        work_item.work_item_type = work_item_type

        expect(work_item.association(:work_item_type).loaded?).to be false
      end
    end

    context 'when we set a system_defined_type' do
      it 'sets the work_item_type_id' do
        # TODO change that to  work_item.work_item_type = system_defined_type once we
        # integrate the system defined types into the types provider
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
        expect { work_item.work_item_type_id = system_defined_type.id }
          .to change { work_item.work_item_type_id }
          .from(nil)
          .to(system_defined_type.id)
      end
    end

    context 'when we set to nil' do
      before do
        work_item.work_item_type_id = work_item_type.id
      end

      it 'sets the work_item_type_id to nil' do
        expect { work_item.work_item_type = nil }
          .to change { work_item.work_item_type_id }
          .from(work_item_type.id)
          .to(nil)
      end
    end

    context 'when we set with an id' do
      it 'sets the work_item_type_id' do
        expect { work_item.work_item_type = work_item_type.id }
          .to change { work_item.work_item_type_id }
          .from(nil)
          .to(work_item_type.id)
      end

      context 'when id corresponds to a system_defined_type' do
        it 'fetches and sets the system_defined_type' do
          expect { work_item.work_item_type = system_defined_type.id }
            .to change { work_item.work_item_type_id }
            .from(nil)
            .to(system_defined_type.id)
        end
      end
    end

    context "when the FF for system defined types is disabled" do
      before do
        stub_feature_flags(work_item_system_defined_type: false)
      end

      it 'uses the belongs_to setter' do
        work_item.work_item_type = work_item_type

        expect(work_item.association(:work_item_type).loaded?).to be true
      end

      it 'calls super' do
        expect(work_item).to receive(:work_item_type=).and_call_original

        work_item.work_item_type = work_item_type
      end

      it 'sets the work_item_type_id' do
        expect { work_item.work_item_type = work_item_type }
          .to change { work_item.work_item_type_id }
          .from(nil)
          .to(work_item_type.id)
      end
    end
  end
end
