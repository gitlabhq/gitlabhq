# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItemPolicy do
  let_it_be(:project) { create(:project) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:guest) { create(:user).tap { |user| project.add_guest(user) } }
  let_it_be(:guest_author) { create(:user).tap { |user| project.add_guest(user) } }
  let_it_be(:reporter) { create(:user).tap { |user| project.add_reporter(user) } }
  let_it_be(:non_member_user) { create(:user) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:authored_work_item) { create(:work_item, project: project, author: guest_author) }
  let_it_be(:public_work_item) { create(:work_item, project: public_project) }

  let(:work_item_subject) { work_item }

  subject { described_class.new(current_user, work_item_subject) }

  before_all do
    public_project.add_developer(guest_author)
  end

  describe 'read_work_item' do
    context 'when project is public' do
      let(:work_item_subject) { public_work_item }

      context 'when user is not a member of the project' do
        let(:current_user) { non_member_user }

        it { is_expected.to be_allowed(:read_work_item) }
      end

      context 'when user is a member of the project' do
        let(:current_user) { guest_author }

        it { is_expected.to be_allowed(:read_work_item) }
      end
    end

    context 'when project is private' do
      let(:work_item_subject) { work_item }

      context 'when user is not a member of the project' do
        let(:current_user) { non_member_user }

        it { is_expected.to be_disallowed(:read_work_item) }
      end

      context 'when user is a member of the project' do
        let(:current_user) { guest_author }

        it { is_expected.to be_allowed(:read_work_item) }
      end
    end
  end

  describe 'update_work_item' do
    context 'when user is reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:update_work_item) }
    end

    context 'when user is guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:update_work_item) }

      context 'when guest authored the work item' do
        let(:work_item_subject) { authored_work_item }
        let(:current_user) { guest_author }

        it { is_expected.to be_allowed(:update_work_item) }
      end
    end
  end

  describe 'delete_work_item' do
    context 'when user is a member of the project' do
      let(:work_item_subject) { work_item }
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:delete_work_item) }

      context 'when guest authored the work item' do
        let(:work_item_subject) { authored_work_item }
        let(:current_user) { guest_author }

        it { is_expected.to be_allowed(:delete_work_item) }
      end
    end
  end
end
