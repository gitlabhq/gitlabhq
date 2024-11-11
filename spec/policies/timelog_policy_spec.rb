# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimelogPolicy, :models do
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:timelog) { create(:timelog, user: author, issue: issue, time_spent: 1800) }

  let(:user) { nil }
  let(:policy) { described_class.new(user, timelog) }

  describe '#rules' do
    context 'when user is anonymus' do
      it 'prevents adimistration of timelog' do
        expect(policy).to be_disallowed(:admin_timelog)
      end
    end

    context 'when user is the author of the timelog' do
      let(:user) { author }

      it 'allows adimistration of timelog' do
        expect(policy).to be_allowed(:admin_timelog)
      end
    end

    context 'when user is not the author of the timelog but maintainer of the project' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
      end

      it 'allows adimistration of timelog' do
        expect(policy).to be_allowed(:admin_timelog)
      end
    end

    context 'when user is not the timelog\'s author, not a maintainer but an administrator', :enable_admin_mode do
      let(:user) { create(:user, :admin) }

      it 'allows adimistration of timelog' do
        expect(policy).to be_allowed(:admin_timelog)
      end
    end

    context 'when user is not the author of the timelog nor a maintainer of the project nor an administrator' do
      let(:user) { create(:user) }

      it 'prevents adimistration of timelog' do
        expect(policy).to be_disallowed(:admin_timelog)
      end
    end
  end
end
