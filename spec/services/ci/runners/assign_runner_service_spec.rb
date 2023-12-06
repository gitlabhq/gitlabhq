# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::AssignRunnerService, '#execute', feature_category: :fleet_visibility do
  subject(:execute) { described_class.new(runner, new_project, user).execute }

  let_it_be(:owner_group) { create(:group) }
  let_it_be(:owner_project) { create(:project, group: owner_group) }
  let_it_be(:new_project) { create(:project) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [owner_project]) }

  context 'without user' do
    let(:user) { nil }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(runner).not_to receive(:assign_to)

      is_expected.to be_error
      expect(execute.message).to eq('user not allowed to assign runner')
    end
  end

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns error message' do
      expect(runner).not_to receive(:assign_to)

      is_expected.to be_error
      expect(execute.message).to eq('user not allowed to assign runner')
    end
  end

  context 'with authorized user' do
    let(:user) { create(:user) }

    context 'with user owning runner and being maintainer of new project' do
      before do
        owner_project.group.add_owner(user)
        new_project.add_maintainer(user)
      end

      it 'calls assign_to on runner and returns success response' do
        expect(runner).to receive(:assign_to).with(new_project, user).once.and_call_original

        is_expected.to be_success
      end
    end

    context 'with user owning runner' do
      before do
        owner_project.add_maintainer(user)
      end

      it 'does not call assign_to on runner and returns error message', :aggregate_failures do
        expect(runner).not_to receive(:assign_to)

        is_expected.to be_error
        expect(execute.message).to eq('user not allowed to add runners to project')
      end
    end

    context 'with user being maintainer of new project', :aggregate_failures do
      before do
        new_project.add_maintainer(user)
      end

      it 'does not call assign_to on runner and returns error message' do
        expect(runner).not_to receive(:assign_to)

        is_expected.to be_error
        expect(execute.message).to eq('user not allowed to assign runner')
      end
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create(:user, :admin) }

    it 'calls assign_to on runner and returns success response' do
      expect(runner).to receive(:assign_to).with(new_project, user).once.and_call_original

      is_expected.to be_success
    end
  end
end
