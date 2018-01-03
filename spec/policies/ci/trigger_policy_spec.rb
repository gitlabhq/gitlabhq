require 'spec_helper'

describe Ci::TriggerPolicy do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:trigger) { create(:ci_trigger, project: project, owner: owner) }

  let(:policies) do
    described_class.new(user, trigger)
  end

  shared_examples 'allows to admin and manage trigger' do
    it 'does include ability to admin trigger' do
      expect(policies).to be_allowed :admin_trigger
    end

    it 'does include ability to manage trigger' do
      expect(policies).to be_allowed :manage_trigger
    end
  end

  shared_examples 'allows to manage trigger' do
    it 'does not include ability to admin trigger' do
      expect(policies).not_to be_allowed :admin_trigger
    end

    it 'does include ability to manage trigger' do
      expect(policies).to be_allowed :manage_trigger
    end
  end

  shared_examples 'disallows to admin and manage trigger' do
    it 'does not include ability to admin trigger' do
      expect(policies).not_to be_allowed :admin_trigger
    end

    it 'does not include ability to manage trigger' do
      expect(policies).not_to be_allowed :manage_trigger
    end
  end

  describe '#rules' do
    context 'when owner is undefined' do
      let(:owner) { nil }

      context 'when user is master of the project' do
        before do
          project.add_master(user)
        end

        it_behaves_like 'allows to admin and manage trigger'
      end

      context 'when user is developer of the project' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'disallows to admin and manage trigger'
      end

      context 'when user is not member of the project' do
        it_behaves_like 'disallows to admin and manage trigger'
      end
    end

    context 'when owner is an user' do
      let(:owner) { user }

      context 'when user is master of the project' do
        before do
          project.add_master(user)
        end

        it_behaves_like 'allows to admin and manage trigger'
      end
    end

    context 'when owner is another user' do
      let(:owner) { create(:user) }

      context 'when user is master of the project' do
        before do
          project.add_master(user)
        end

        it_behaves_like 'allows to manage trigger'
      end

      context 'when user is developer of the project' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'disallows to admin and manage trigger'
      end

      context 'when user is not member of the project' do
        it_behaves_like 'disallows to admin and manage trigger'
      end
    end
  end
end
