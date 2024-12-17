# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::ReorderService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be_with_reload(:parent) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:work_item) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:top_adjacent) { create(:work_item, :objective, project: project) }
    let_it_be_with_reload(:last_adjacent) { create(:work_item, :objective, project: project) }

    let(:parent_link_class) { WorkItems::ParentLink }
    let(:user) { guest }
    let(:params) { { target_issuable: work_item } }
    # be_between only works when the lower value is the first in the array
    let(:relative_range) { [top_adjacent, last_adjacent].map(&:parent_link).map(&:relative_position).sort }

    subject(:reorder) { described_class.new(parent, user, params).execute }

    before do
      project.add_guest(guest)

      create(:parent_link, work_item: top_adjacent, work_item_parent: parent)
      create(:parent_link, work_item: last_adjacent, work_item_parent: parent)
    end

    shared_examples 'raises a service error' do |message, status = 409|
      it { is_expected.to eq(service_error(message, http_status: status)) }
    end

    shared_examples 'returns not found error' do
      it 'returns error' do
        error = "No matching work item found. Make sure that you are adding a valid work item ID."

        is_expected.to eq(service_error(error))
      end

      it 'creates no relationship' do
        expect { subject }.not_to change { parent_link_class.count }
      end
    end

    shared_examples 'returns conflict error' do
      it_behaves_like 'raises a service error', 'Work item(s) already assigned'

      it 'creates no relationship' do
        expect { subject }.to not_change { parent_link_class.count }
      end
    end

    shared_examples 'processes ordered hierarchy' do
      it 'returns success status and processed links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].map(&:work_item_id)).to match_array([work_item.id])
      end

      it 'orders hierarchy' do
        subject

        expect(last_adjacent.parent_link.relative_position).to be_between(*relative_range)
      end

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        let(:update_subject) { parent }
        let(:execute_service) { subject }
      end
    end

    context 'when user has insufficient permissions' do
      let(:user) { create(:user) }

      it_behaves_like 'returns not found error'

      context 'when user is a guest assigned to the work item' do
        before do
          work_item.assignees = [guest]
        end

        it_behaves_like 'returns not found error'
      end
    end

    context 'when child and parent are already linked' do
      before do
        create(:parent_link, work_item: work_item, work_item_parent: parent)
      end

      it_behaves_like 'returns conflict error'

      context 'when adjacents are already in place and the user has sufficient permissions' do
        let(:base_param) { { target_issuable: work_item } }

        shared_examples 'updates hierarchy order without notes' do
          it_behaves_like 'processes ordered hierarchy'

          it 'keeps relationships', :aggregate_failures do
            expect { subject }.to not_change { parent_link_class.count }

            expect(parent_link_class.where(work_item: work_item).last.work_item_parent).to eq(parent)
          end

          it 'does not create notes', :aggregate_failures do
            expect { subject }.to not_change { work_item.notes.count }.and(not_change { work_item.notes.count })
          end
        end

        context 'when moving before adjacent work item' do
          let(:params) { base_param.merge({ adjacent_work_item: last_adjacent, relative_position: 'BEFORE' }) }

          it_behaves_like 'updates hierarchy order without notes'
        end

        context 'when moving after adjacent work item' do
          let(:params) { base_param.merge({ adjacent_work_item: top_adjacent, relative_position: 'AFTER' }) }

          it_behaves_like 'updates hierarchy order without notes'
        end
      end
    end

    context 'when new parent is assigned' do
      shared_examples 'updates hierarchy order and creates notes' do
        it_behaves_like 'processes ordered hierarchy'

        it 'creates notes', :aggregate_failures do
          subject

          expect(parent.notes.last.note).to eq("added #{work_item.to_reference} as child objective")
          expect(work_item.notes.last.note).to eq("added #{parent.to_reference} as parent objective")
        end
      end

      context 'when adjacents are already in place and the user has sufficient permissions' do
        let(:base_param) { { target_issuable: work_item } }

        context 'when moving before adjacent work item' do
          let(:params) { base_param.merge({ adjacent_work_item: last_adjacent, relative_position: 'BEFORE' }) }

          it_behaves_like 'updates hierarchy order and creates notes'
        end

        context 'when moving after adjacent work item' do
          let(:params) { base_param.merge({ adjacent_work_item: top_adjacent, relative_position: 'AFTER' }) }

          it_behaves_like 'updates hierarchy order and creates notes'
        end

        context 'when previous parent was in place' do
          before do
            create(:parent_link, work_item: work_item,
              work_item_parent: create(:work_item, :objective, project: project))
          end

          context 'when moving before adjacent work item' do
            let(:params) { base_param.merge({ adjacent_work_item: last_adjacent, relative_position: 'BEFORE' }) }

            it_behaves_like 'updates hierarchy order and creates notes'
          end

          context 'when moving after adjacent work item' do
            let(:params) { base_param.merge({ adjacent_work_item: top_adjacent, relative_position: 'AFTER' }) }

            it_behaves_like 'updates hierarchy order and creates notes'
          end
        end
      end

      context 'when no adjacent item or relative position is provided' do
        let(:params) { { target_issuable: work_item } }

        it 'returns success status and processed links', :aggregate_failures do
          expect(reorder.keys).to match_array([:status, :created_references])
          expect(reorder[:status]).to eq(:success)
          expect(reorder[:created_references].map(&:work_item_id)).to match_array([work_item.id])
        end

        it 'places the item at the top of the list' do
          reorder

          expect(work_item.parent_link.relative_position).to be < top_adjacent.parent_link.relative_position
        end
      end
    end
  end

  def service_error(message, http_status: 404)
    {
      message: message,
      status: :error,
      http_status: http_status
    }
  end
end
