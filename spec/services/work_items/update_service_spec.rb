# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateService do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project).tap { |proj| proj.add_developer(developer) } }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, assignees: [developer]) }

  let(:spam_params) { double }
  let(:opts) { {} }
  let(:current_user) { developer }

  describe '#execute' do
    subject(:update_work_item) { described_class.new(project: project, current_user: current_user, params: opts, spam_params: spam_params).execute(work_item) }

    before do
      stub_spam_services
    end

    context 'when updating state_event' do
      context 'when state_event is close' do
        let(:opts) { { state_event: 'close' } }

        it 'closes the work item' do
          expect do
            update_work_item
            work_item.reload
          end.to change(work_item, :state).from('opened').to('closed')
        end
      end

      context 'when state_event is reopen' do
        let(:opts) { { state_event: 'reopen' } }

        before do
          work_item.close!
        end

        it 'reopens the work item' do
          expect do
            update_work_item
            work_item.reload
          end.to change(work_item, :state).from('closed').to('opened')
        end
      end
    end
  end
end
