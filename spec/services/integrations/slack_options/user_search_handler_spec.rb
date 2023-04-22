# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackOptions::UserSearchHandler, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:chat_name) { create(:chat_name, user: current_user) }
    let_it_be(:user1) { create(:user, name: 'Rajendra Kadam') }
    let_it_be(:user2) { create(:user, name: 'Rajesh K') }
    let_it_be(:user3) { create(:user) }
    let_it_be(:view_id) { 'VXHD54DR' }

    let(:search_value) { 'Raj' }

    subject(:execute) { described_class.new(chat_name, search_value, view_id).execute }

    context 'when user has permissions to read project members' do
      before do
        project.add_developer(current_user)
        project.add_guest(user1)
        project.add_reporter(user2)
        project.add_maintainer(user3)
      end

      it 'returns the user matching the search term' do
        expect(Rails.cache).to receive(:read).and_return(project.id)

        members = execute.payload[:options]
        user_names = members.map { |member| member.dig(:text, :text) }

        expect(members.count).to eq(2)
        expect(user_names).to contain_exactly(
          "#{user1.name} - #{user1.username}",
          "#{user2.name} - #{user2.username}"
        )
      end
    end

    context 'when user does not have permissions to read project members' do
      it 'returns empty array' do
        expect(Rails.cache).to receive(:read).and_return(project.id)
        expect(MembersFinder).not_to receive(:execute)

        members = execute.payload

        expect(members).to be_empty
      end
    end
  end
end
