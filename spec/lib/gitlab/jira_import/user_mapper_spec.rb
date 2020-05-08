# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::UserMapper do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user)    { create(:user, email: 'user@example.com') }
  let_it_be(:email)   { create(:email, user: user, email: 'second_email@example.com', confirmed_at: nil) }

  let(:jira_user) { { 'acountId' => '1a2b', 'emailAddress' => 'user@example.com' } }

  describe '#execute' do
    subject { described_class.new(project, jira_user).execute }

    context 'when jira_user is nil' do
      let(:jira_user) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when Gitlab user is not found by email' do
      let(:jira_user) { { 'acountId' => '1a2b', 'emailAddress' => 'other@example.com' } }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when jira_user emailAddress is nil' do
      let(:jira_user) { { 'acountId' => '1a2b', 'emailAddress' => nil } }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when jira_user emailAddress key is missing' do
      let(:jira_user) { { 'acountId' => '1a2b' } }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when found user is not a project member' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when found user is a project member' do
      it 'returns the found user' do
        project.add_developer(user)

        expect(subject).to eq(user)
      end
    end

    context 'when user found by unconfirmd secondary address is a project member' do
      let(:jira_user) { { 'acountId' => '1a2b', 'emailAddress' => 'second_email@example.com' } }

      it 'returns the found user' do
        project.add_developer(user)

        expect(subject).to eq(user)
      end
    end

    context 'when user is a group member' do
      it 'returns the found user' do
        group.add_developer(user)

        expect(subject).to eq(user)
      end
    end
  end
end
