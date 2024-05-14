# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::Notes, feature_category: :team_planning do
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, guests: guest, reporters: reporter) }
  let_it_be_with_reload(:work_item) do
    create(:work_item, project: project, author: guest, discussion_locked: nil)
  end

  let(:current_user) { guest }
  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Notes) } }
  let(:discussion_locked) { true }
  let(:params) { { discussion_locked: discussion_locked } }
  let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

  subject(:update_discussion_locked) { service.before_update }

  describe '#before_update_callback' do
    shared_examples 'discussion_locked is unchanged' do
      it 'does not change the discussion_locked of the work item' do
        expect { update_discussion_locked }.to not_change { work_item.discussion_locked }
      end
    end

    context 'when discussion_locked param is not present' do
      let(:params) { {} }

      it_behaves_like 'discussion_locked is unchanged'
    end

    context 'when user cannot set work item metadata' do
      let(:current_user) { guest }

      it_behaves_like 'discussion_locked is unchanged'
    end

    context 'when user can set work item metadata' do
      let(:current_user) { reporter }

      it 'sets the discussion_locked for the work item' do
        expect { update_discussion_locked }.to change { work_item.discussion_locked }.from(nil).to(true)
      end

      context 'when widget does not exist in new type' do
        let(:params) { {} }

        before do
          allow(service).to receive(:new_type_excludes_widget?).and_return(true)
          work_item.discussion_locked = true
        end

        it "keeps item's discussion_locked value intact" do
          expect { update_discussion_locked }.not_to change { work_item.discussion_locked }
        end
      end
    end
  end
end
