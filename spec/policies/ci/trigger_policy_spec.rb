# frozen_string_literal: true

require 'spec_helper'

describe Ci::TriggerPolicy do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:trigger) { create(:ci_trigger, project: project, owner: create(:user)) }

  subject { described_class.new(user, trigger) }

  describe '#rules' do
    context 'when owner is an user' do
      before do
        trigger.update!(owner: user)
      end

      context 'when user is maintainer of the project' do
        before do
          project.add_maintainer(user)
        end

        it { is_expected.to be_allowed(:manage_trigger) }
        it { is_expected.to be_allowed(:admin_trigger) }
      end
    end

    context 'when owner is another user' do
      context 'when user is maintainer of the project' do
        before do
          project.add_maintainer(user)
        end

        it { is_expected.to be_allowed(:manage_trigger) }
        it { is_expected.not_to be_allowed(:admin_trigger) }
      end

      context 'when user is developer of the project' do
        before do
          project.add_developer(user)
        end

        it { is_expected.not_to be_allowed(:manage_trigger) }
        it { is_expected.not_to be_allowed(:admin_trigger) }
      end

      context 'when user is not member of the project' do
        it { is_expected.not_to be_allowed(:manage_trigger) }
        it { is_expected.not_to be_allowed(:admin_trigger) }
      end
    end
  end
end
