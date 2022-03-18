# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::AssignRunnerService, '#execute' do
  subject { described_class.new(runner, project, user).execute }

  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:project) { create(:project) }

  context 'without user' do
    let(:user) { nil }

    it 'does not call assign_to on runner and returns false' do
      expect(runner).not_to receive(:assign_to)

      is_expected.to eq(false)
    end
  end

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns false' do
      expect(runner).not_to receive(:assign_to)

      is_expected.to eq(false)
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:user, :admin) }

    it 'calls assign_to on runner and returns value unchanged' do
      expect(runner).to receive(:assign_to).with(project, user).once.and_return('assign_to return value')

      is_expected.to eq('assign_to return value')
    end
  end
end
