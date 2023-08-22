# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UserAccessSnippet do
  subject(:access) { described_class.new(user, snippet: snippet) }

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:snippet) { create(:project_snippet, :private, project: project) }
  let_it_be(:migration_bot) { Users::Internal.migration_bot }

  let(:user) { create(:user) }

  describe '#can_do_action?' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :ability, snippet).and_return(:foo)
    end

    context 'when can access_git' do
      it 'calls Ability#allowed? and returns its result' do
        expect(access.can_do_action?(:ability)).to eq(:foo)
      end
    end

    context 'when can not access_git' do
      it 'disallows access' do
        expect(Ability).to receive(:allowed?).with(user, :access_git, :global).and_return(false)

        expect(access.can_do_action?(:ability)).to eq(false)
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it 'disallows access' do
        expect(access.can_do_action?(:ability)).to eq(false)
      end
    end

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it 'allows access' do
        expect(access.can_do_action?(:ability)).to eq(true)
      end
    end
  end

  describe '#can_push_to_branch?' do
    include UserHelpers

    [:anonymous, :non_member, :guest, :reporter, :maintainer, :admin, :author].each do |membership|
      context membership.to_s do
        let(:user) do
          membership == :author ? snippet.author : create_user_from_membership(project, membership)
        end

        context 'when can access_git' do
          it 'respects accessibility' do
            expected_result = Ability.allowed?(user, :update_snippet, snippet)

            expect(access.can_push_to_branch?('random_branch')).to eq(expected_result)
          end
        end

        context 'when can not access_git' do
          it 'disallows access' do
            expect(Ability).to receive(:allowed?).with(user, :access_git, :global).and_return(false) if user

            expect(access.can_push_to_branch?('random_branch')).to eq(false)
          end
        end
      end
    end

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it 'allows access' do
        allow(Ability).to receive(:allowed?).and_return(false)

        expect(access.can_push_to_branch?('random_branch')).to eq(true)
      end
    end

    context 'when snippet is nil' do
      let(:user) { create_user_from_membership(project, :admin) }
      let(:snippet) { nil }

      it 'disallows access' do
        expect(access.can_push_to_branch?('random_branch')).to eq(false)
      end

      context 'when user is migration bot' do
        let(:user) { migration_bot }

        it 'disallows access' do
          expect(access.can_push_to_branch?('random_branch')).to eq(false)
        end
      end
    end
  end

  describe '#can_create_tag?' do
    it 'returns false' do
      expect(access.can_create_tag?('random_tag')).to be_falsey
    end

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it 'returns false' do
        expect(access.can_create_tag?('random_tag')).to be_falsey
      end
    end
  end

  describe '#can_delete_branch?' do
    it 'returns false' do
      expect(access.can_delete_branch?('random_branch')).to be_falsey
    end

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it 'returns false' do
        expect(access.can_delete_branch?('random_branch')).to be_falsey
      end
    end
  end

  describe '#can_merge_to_branch?' do
    it 'returns false' do
      expect(access.can_merge_to_branch?('random_branch')).to be_falsey
    end

    context 'when user is migration bot' do
      let(:user) { migration_bot }

      it 'returns false' do
        expect(access.can_merge_to_branch?('random_branch')).to be_falsey
      end
    end
  end
end
