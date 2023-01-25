# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipantPresenter, feature_category: :service_desk do
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/389247
  # for details around build_stubbed for access level
  let_it_be(:non_member) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:guest) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:reporter) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:developer) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:group) { create(:group) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project, group: group) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:issue) { build_stubbed(:issue, project: project) }
  let_it_be(:participant) { build_stubbed(:issue_email_participant, issue: issue, email: 'any@email.com') }

  let(:user) { nil }
  let(:presenter) { described_class.new(participant, current_user: user) }
  let(:obfuscated_email) { 'an*****@e*****.c**' }
  let(:email) { 'any@email.com' }

  before_all do
    group.add_guest(guest)
    group.add_reporter(reporter)
    group.add_developer(developer)
  end

  describe '#email' do
    subject { presenter.email }

    it { is_expected.to eq(obfuscated_email) }

    context 'with signed in user' do
      context 'when user has no role in project' do
        let(:user) { non_member }

        it { is_expected.to eq(obfuscated_email) }
      end

      context 'when user has guest role in project' do
        let(:user) { guest }

        it { is_expected.to eq(obfuscated_email) }
      end

      context 'when user has reporter role in project' do
        let(:user) { reporter }

        it { is_expected.to eq(email) }
      end

      context 'when user has developer role in project' do
        let(:user) { developer }

        it { is_expected.to eq(email) }
      end
    end
  end
end
