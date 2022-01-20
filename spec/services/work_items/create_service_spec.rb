# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateService do
  include AfterNextHelpers

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let(:spam_params) { double }

  describe '#execute' do
    let(:work_item) { described_class.new(project: project, current_user: user, params: opts, spam_params: spam_params).execute }

    before do
      stub_spam_services
    end

    context 'when params are valid' do
      before_all do
        project.add_guest(user)
      end

      let(:opts) do
        {
          title: 'Awesome work_item',
          description: 'please fix'
        }
      end

      it 'created instance is a WorkItem' do
        expect(Issuable::CommonSystemNotesService).to receive_message_chain(:new, :execute)

        expect(work_item).to be_persisted
        expect(work_item).to be_a(::WorkItem)
        expect(work_item.title).to eq('Awesome work_item')
        expect(work_item.description).to eq('please fix')
        expect(work_item.work_item_type.base_type).to eq('issue')
      end
    end

    context 'checking spam' do
      let(:params) do
        {
          title: 'Spam work_item'
        }
      end

      subject do
        described_class.new(project: project, current_user: user, params: params, spam_params: spam_params)
      end

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

        subject.execute
      end
    end
  end
end
