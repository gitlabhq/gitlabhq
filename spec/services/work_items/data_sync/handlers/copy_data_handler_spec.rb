# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Handlers::CopyDataHandler, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target_namespace) { project.project_namespace }
  let_it_be(:target_work_item_type) { create(:work_item_type) }
  let_it_be(:current_user) { create(:user) }

  let(:params) { { operation: 'move', data_sync_params: { some_param: "some data" } } }
  let(:overwritten_params) { { overwritten: 'params' } }

  subject(:copy_data_handler) do
    described_class.new(
      work_item: work_item,
      target_namespace: target_namespace,
      target_work_item_type: target_work_item_type,
      current_user: current_user,
      params: params,
      overwritten_params: overwritten_params
    )
  end

  describe '#execute' do
    let(:base_create_service) { instance_double(WorkItems::DataSync::BaseCreateService) }

    before do
      allow(WorkItems::DataSync::BaseCreateService).to receive(:new).and_return(base_create_service)
    end

    it 'calls BaseCreateService with correct parameters' do
      result = ServiceResponse.success(payload: { work_item: instance_double(WorkItem) })

      allow(base_create_service).to receive(:execute)

      expect(WorkItems::DataSync::BaseCreateService).to receive(:new).with(
        original_work_item: work_item,
        container: target_namespace,
        current_user: current_user,
        operation: anything,
        params: copy_data_handler.create_params.merge(params.except(:operation))
      ).and_return(base_create_service)
      expect(base_create_service).to receive(:execute).with(skip_system_notes: true).and_return(result)
      allow(copy_data_handler).to receive(:maintaining_elasticsearch?).and_return(false)

      copy_data_handler.execute
    end

    context 'when BaseCreateService raises an error' do
      it 'raises error' do
        allow(base_create_service).to receive(:execute).and_raise("Some error")

        expect { copy_data_handler.execute }.to raise_error("Some error")
      end
    end
  end

  describe '#relative_position' do
    context 'when work_item and target_namespace have the same root ancestor' do
      before do
        allow(work_item.namespace).to receive(:root_ancestor).and_return(target_namespace.root_ancestor)
      end

      it 'returns the work_item relative_position' do
        expect(copy_data_handler.send(:relative_position)).to eq(work_item.relative_position)
      end
    end

    context 'when work_item and target_namespace have different root ancestors' do
      before do
        allow(work_item.namespace).to receive(:root_ancestor).and_return(create(:namespace))
      end

      it 'returns nil' do
        expect(copy_data_handler.send(:relative_position)).to be_nil
      end
    end
  end

  describe '#project' do
    context 'when target_namespace is a ProjectNamespace' do
      it 'returns the project' do
        expect(copy_data_handler.send(:project)).to eq(project)
      end
    end

    context 'when target_namespace is not a ProjectNamespace' do
      let(:target_namespace) { group }

      it 'returns nil' do
        expect(copy_data_handler.send(:project)).to be_nil
      end
    end
  end

  describe '#service_desk_reply_to' do
    it 'returns the target_namespace service_desk_alias_address' do
      allow_next_instance_of ::ServiceDesk::Emails do |emails|
        allow(emails).to receive(:alias_address).and_return('service_desk@example.com')
      end

      expect(copy_data_handler.send(:service_desk_reply_to)).to eq('service_desk@example.com')
    end
  end
end
