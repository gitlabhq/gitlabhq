# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateService do
  include AfterNextHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:user_with_no_access) { create(:user) }

  let(:spam_params) { double }
  let(:current_user) { guest }
  let(:opts) do
    {
      title: 'Awesome work_item',
      description: 'please fix'
    }
  end

  before_all do
    project.add_guest(guest)
  end

  describe '#execute' do
    subject(:service_result) { described_class.new(project: project, current_user: current_user, params: opts, spam_params: spam_params).execute }

    before do
      stub_spam_services
    end

    context 'when user is not allowed to create a work item in the project' do
      let(:current_user) { user_with_no_access }

      it { is_expected.to be_error }

      it 'returns an access error' do
        expect(service_result.errors).to contain_exactly('Operation not allowed')
      end
    end

    context 'when params are valid' do
      it 'created instance is a WorkItem' do
        expect(Issuable::CommonSystemNotesService).to receive_message_chain(:new, :execute)

        work_item = service_result[:work_item]

        expect(work_item).to be_persisted
        expect(work_item).to be_a(::WorkItem)
        expect(work_item.title).to eq('Awesome work_item')
        expect(work_item.description).to eq('please fix')
        expect(work_item.work_item_type.base_type).to eq('issue')
      end
    end

    context 'when params are invalid' do
      let(:opts) { { title: '' } }

      it { is_expected.to be_error }

      it 'returns validation errors' do
        expect(service_result.errors).to contain_exactly("Title can't be blank")
      end
    end

    context 'checking spam' do
      it 'executes SpamActionService' do
        expect_next_instance_of(
          Spam::SpamActionService,
          {
            spammable: kind_of(WorkItem),
            spam_params: spam_params,
            user: an_instance_of(User),
            action: :create
          }
        ) do |instance|
          expect(instance).to receive(:execute)
        end

        service_result
      end
    end
  end
end
