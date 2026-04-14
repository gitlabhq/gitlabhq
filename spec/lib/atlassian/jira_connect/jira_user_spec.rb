# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::JiraUser, feature_category: :integrations do
  describe '#jira_admin?' do
    context 'when user is a member of site-admins' do
      let(:user) do
        described_class.new(
          { 'groups' => { 'items' => [{ 'name' => 'site-admins' }] } }
        )
      end

      it { expect(user.jira_admin?).to be true }
    end

    context 'when user is a member of org-admins' do
      let(:user) do
        described_class.new(
          { 'groups' => { 'items' => [{ 'name' => 'org-admins' }] } }
        )
      end

      it { expect(user.jira_admin?).to be true }
    end

    context 'when user is not a member of any admin group' do
      let(:user) do
        described_class.new(
          {
            'groups' => {
              'items' => [
                { 'name' => 'jira-users' },
                { 'name' => 'developers' }
              ]
            }
          }
        )
      end

      it { expect(user.jira_admin?).to be false }
    end

    context 'when groups data is missing' do
      let(:user) { described_class.new({}) }

      it { expect(user.jira_admin?).to be false }
    end

    context 'when groups items is nil' do
      let(:user) do
        described_class.new({ 'groups' => {} })
      end

      it { expect(user.jira_admin?).to be false }
    end
  end

  describe '#not_an_admin_error_message' do
    context 'when user is a jira admin' do
      let(:user) do
        described_class.new(
          { 'groups' => { 'items' => [{ 'name' => 'org-admins' }] } }
        )
      end

      it 'returns nil' do
        expect(user.not_an_admin_error_message).to be_nil
      end
    end

    context 'when user has groups but none are admin groups' do
      let(:user) do
        described_class.new(
          {
            'groups' => {
              'items' => [
                { 'name' => 'jira-users' },
                { 'name' => 'developers' }
              ]
            }
          }
        )
      end

      it 'includes the required admin groups' do
        expect(user.not_an_admin_error_message).to include(
          'site-admins or org-admins'
        )
      end

      it 'includes the current group names' do
        expect(user.not_an_admin_error_message).to include(
          'jira-users, developers'
        )
      end
    end

    context 'when user has no groups' do
      let(:user) do
        described_class.new(
          { 'groups' => { 'items' => [] } }
        )
      end

      it 'indicates the user has no group memberships' do
        expect(user.not_an_admin_error_message).to include(
          'not a member of any Jira groups'
        )
      end

      it 'lists the required groups' do
        expect(user.not_an_admin_error_message).to include(
          'site-admins, org-admins'
        )
      end
    end

    context 'when groups data is entirely missing' do
      let(:user) { described_class.new({}) }

      it 'indicates the user has no group memberships' do
        expect(user.not_an_admin_error_message).to include(
          'not a member of any Jira groups'
        )
      end
    end
  end
end
