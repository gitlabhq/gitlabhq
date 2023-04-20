# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEmailParticipantPresenter, feature_category: :service_desk do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:issue) { build_stubbed(:issue, project: project) }
  let(:participant) { build_stubbed(:issue_email_participant, issue: issue, email: 'any@example.com') }
  let(:obfuscated_email) { 'an*****@e*****.c**' }
  let(:email) { 'any@example.com' }

  subject(:presenter) { described_class.new(participant, current_user: user) }

  describe '#email' do
    subject { presenter.email }

    context 'when anonymous' do
      let(:user) { nil }

      it { is_expected.to eq(obfuscated_email) }
    end

    context 'with signed in user' do
      before do
        stub_member_access_level(project, access_level => user) if access_level
      end

      context 'when user has no role in project' do
        let(:access_level) { nil }

        it { is_expected.to eq(obfuscated_email) }
      end

      context 'when user has guest role in project' do
        let(:access_level) { :guest }

        it { is_expected.to eq(obfuscated_email) }
      end

      context 'when user has reporter role in project' do
        let(:access_level) { :reporter }

        it { is_expected.to eq(email) }
      end

      context 'when user has developer role in project' do
        let(:access_level) { :developer }

        it { is_expected.to eq(email) }
      end
    end
  end
end
