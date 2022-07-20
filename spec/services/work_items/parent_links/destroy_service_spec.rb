# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::DestroyService do
  describe '#execute' do
    let_it_be(:reporter) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:task) { create(:work_item, :task, project: project) }
    let_it_be(:parent_link) { create(:parent_link, work_item: task, work_item_parent: work_item)}

    let(:parent_link_class) { WorkItems::ParentLink }

    subject { described_class.new(parent_link, user).execute }

    before do
      project.add_reporter(reporter)
      project.add_guest(guest)
    end

    context 'when user has permissions to update work items' do
      let(:user) { reporter }

      it 'removes relation' do
        expect { subject }.to change(parent_link_class, :count).by(-1)
      end

      it 'returns success message' do
        is_expected.to eq(message: 'Relation was removed', status: :success)
      end
    end

    context 'when user has insufficient permissions' do
      let(:user) { guest }

      it 'does not remove relation' do
        expect { subject }.not_to change(parent_link_class, :count).from(1)
      end

      it 'returns error message' do
        is_expected.to eq(message: 'No Work Item Link found', status: :error, http_status: 404)
      end
    end
  end
end
