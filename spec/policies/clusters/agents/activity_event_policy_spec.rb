# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::ActivityEventPolicy do
  let_it_be(:event) { create(:agent_activity_event) }

  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, event) }
  let(:project) { event.agent.project }

  describe 'rules' do
    context 'reporter' do
      before do
        project.add_reporter(user)
      end

      it { expect(policy).to be_disallowed :admin_cluster }
      it { expect(policy).to be_disallowed :read_cluster }
    end

    context 'developer' do
      before do
        project.add_developer(user)
      end

      it { expect(policy).to be_disallowed :admin_cluster }
      it { expect(policy).to be_allowed :read_cluster }
    end

    context 'maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { expect(policy).to be_allowed :admin_cluster }
      it { expect(policy).to be_allowed :read_cluster }
    end
  end
end
