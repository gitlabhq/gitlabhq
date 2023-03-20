# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DeleteService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project, author: guest) }

  let(:user) { guest }

  before_all do
    project.add_guest(guest)
    # note necessary to test note removal as part of work item deletion
    create(:note, project: project, noteable: work_item)
  end

  describe '#execute' do
    subject(:result) { described_class.new(container: project, current_user: user).execute(work_item) }

    context 'when user can delete the work item' do
      it { is_expected.to be_success }

      # currently we don't expect destroy to fail. Mocking here for coverage and keeping
      # the service's return type consistent
      context 'when there are errors preventing to delete the work item' do
        before do
          allow(work_item).to receive(:destroy).and_return(false)
          work_item.errors.add(:title)
        end

        it { is_expected.to be_error }

        it 'returns error messages' do
          expect(result.errors).to contain_exactly('Title is invalid')
        end
      end
    end

    context 'when user cannot delete the work item' do
      let(:user) { create(:user) }

      it { is_expected.to be_error }

      it 'returns error messages' do
        expect(result.errors).to contain_exactly('User not authorized to delete work item')
      end
    end
  end
end
