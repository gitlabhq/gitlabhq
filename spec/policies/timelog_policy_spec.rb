# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimelogPolicy, :models do
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:timelog) { create(:timelog, user: author, issue: issue, time_spent: 1800) }

  let(:user) { nil }

  subject { described_class.new(user, timelog) }

  describe '#rules' do
    context 'when user is anonymous' do
      it { expect_disallowed(:delete_timelog) }
    end

    context 'when user is the author of the timelog' do
      let(:user) { author }

      context 'when user is a guest on the project' do
        before_all do
          project.add_guest(author)
        end

        it { expect_allowed(:delete_timelog) }
      end

      context 'when user has no role on a private project' do
        let_it_be(:private_project) { create(:project, :private) }
        let_it_be(:private_issue) { create(:issue, project: private_project) }
        let_it_be(:private_timelog) { create(:timelog, user: author, issue: private_issue, time_spent: 1800) }

        subject { described_class.new(user, private_timelog) }

        it { expect_disallowed(:delete_timelog) }
      end
    end

    context 'when user is not the author of the timelog but maintainer of the project' do
      let_it_be(:user) { create(:user) }

      before_all do
        project.add_maintainer(user)
      end

      it { expect_allowed(:delete_timelog) }
    end

    context 'when user is not the timelog\'s author, not a maintainer but an administrator', :enable_admin_mode do
      let_it_be(:user) { create(:user, :admin) }

      it { expect_allowed(:delete_timelog) }
    end

    context 'when user is not the author of the timelog nor a maintainer of the project nor an administrator' do
      let_it_be(:user) { create(:user) }

      it { expect_disallowed(:delete_timelog) }
    end
  end
end
