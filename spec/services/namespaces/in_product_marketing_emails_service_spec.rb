# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsService, '#execute' do
  subject(:execute_service) { described_class.new(track, interval).execute }

  let(:track) { :create }
  let(:interval) { 1 }

  let(:previous_action_completed_at) { 2.days.ago.middle_of_day }
  let(:current_action_completed_at) { nil }
  let(:experiment_enabled) { true }
  let(:user_can_perform_current_track_action) { true }
  let(:actions_completed) { { created_at: previous_action_completed_at, git_write_at: current_action_completed_at } }

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, email_opted_in: true) }

  before do
    create(:onboarding_progress, namespace: group, **actions_completed)
    group.add_developer(user)
    stub_experiment_for_subject(in_product_marketing_emails: experiment_enabled)
    allow(Ability).to receive(:allowed?).with(user, anything, anything).and_return(user_can_perform_current_track_action)
    allow(Notify).to receive(:in_product_marketing_email).and_return(double(deliver_later: nil))
  end

  RSpec::Matchers.define :send_in_product_marketing_email do |*args|
    match do
      expect(Notify).to have_received(:in_product_marketing_email).with(*args).once
    end

    match_when_negated do
      expect(Notify).not_to have_received(:in_product_marketing_email)
    end
  end

  context 'for each track and series with the right conditions' do
    using RSpec::Parameterized::TableSyntax

    where(:track, :interval, :actions_completed) do
      :create | 1  | { created_at: 2.days.ago.middle_of_day }
      :create | 5  | { created_at: 6.days.ago.middle_of_day }
      :create | 10 | { created_at: 11.days.ago.middle_of_day }
      :verify | 1  | { created_at: 2.days.ago.middle_of_day, git_write_at: 2.days.ago.middle_of_day }
      :verify | 5  | { created_at: 6.days.ago.middle_of_day, git_write_at: 6.days.ago.middle_of_day }
      :verify | 10 | { created_at: 11.days.ago.middle_of_day, git_write_at: 11.days.ago.middle_of_day }
      :trial  | 1  | { created_at: 2.days.ago.middle_of_day, git_write_at: 2.days.ago.middle_of_day, pipeline_created_at: 2.days.ago.middle_of_day }
      :trial  | 5  | { created_at: 6.days.ago.middle_of_day, git_write_at: 6.days.ago.middle_of_day, pipeline_created_at: 6.days.ago.middle_of_day }
      :trial  | 10 | { created_at: 11.days.ago.middle_of_day, git_write_at: 11.days.ago.middle_of_day, pipeline_created_at: 11.days.ago.middle_of_day }
      :team   | 1  | { created_at: 2.days.ago.middle_of_day, git_write_at: 2.days.ago.middle_of_day, pipeline_created_at: 2.days.ago.middle_of_day, trial_started_at: 2.days.ago.middle_of_day }
      :team   | 5  | { created_at: 6.days.ago.middle_of_day, git_write_at: 6.days.ago.middle_of_day, pipeline_created_at: 6.days.ago.middle_of_day, trial_started_at: 6.days.ago.middle_of_day }
      :team   | 10 | { created_at: 11.days.ago.middle_of_day, git_write_at: 11.days.ago.middle_of_day, pipeline_created_at: 11.days.ago.middle_of_day, trial_started_at: 11.days.ago.middle_of_day }
    end

    with_them do
      it { is_expected.to send_in_product_marketing_email(user.id, group.id, track, described_class::INTERVAL_DAYS.index(interval)) }
    end
  end

  context 'when initialized with a different track' do
    let(:track) { :verify }

    it { is_expected.not_to send_in_product_marketing_email }

    context 'when the previous track actions have been completed' do
      let(:current_action_completed_at) { 2.days.ago.middle_of_day }

      it { is_expected.to send_in_product_marketing_email(user.id, group.id, :verify, 0) }
    end
  end

  context 'when initialized with a different interval' do
    let(:interval) { 5 }

    it { is_expected.not_to send_in_product_marketing_email }

    context 'when the previous track action was completed within the intervals range' do
      let(:previous_action_completed_at) { 6.days.ago.middle_of_day }

      it { is_expected.to send_in_product_marketing_email(user.id, group.id, :create, 1) }
    end
  end

  describe 'experimentation' do
    context 'when the experiment is enabled' do
      it 'adds the group as an experiment subject in the experimental group' do
        expect(Experiment).to receive(:add_group)
          .with(:in_product_marketing_emails, variant: :experimental, group: group)

        execute_service
      end
    end

    context 'when the experiment is disabled' do
      let(:experiment_enabled) { false }

      it 'adds the group as an experiment subject in the control group' do
        expect(Experiment).to receive(:add_group)
          .with(:in_product_marketing_emails, variant: :control, group: group)

        execute_service
      end

      it { is_expected.not_to send_in_product_marketing_email }
    end
  end

  context 'when the previous track action is not yet completed' do
    let(:previous_action_completed_at) { nil }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context 'when the previous track action is completed outside the intervals range' do
    let(:previous_action_completed_at) { 3.days.ago }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context 'when the current track action is completed' do
    let(:current_action_completed_at) { Time.current }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context "when the user cannot perform the current track's action" do
    let(:user_can_perform_current_track_action) { false }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context 'when the user has not opted into marketing emails' do
    let(:user) { create(:user, email_opted_in: false) }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context 'when the user has already received a marketing email as part of another group' do
    before do
      other_group = create(:group)
      other_group.add_developer(user)
      create(:onboarding_progress, namespace: other_group, created_at: previous_action_completed_at, git_write_at: current_action_completed_at)
    end

    # For any group Notify is called exactly once
    it { is_expected.to send_in_product_marketing_email(user.id, anything, :create, 0) }
  end

  context 'when invoked with a non existing track' do
    let(:track) { :foo }

    before do
      stub_const("#{described_class}::TRACKS", { foo: :git_write })
    end

    it { expect { subject }.to raise_error(NotImplementedError, 'No ability defined for track foo') }
  end
end
