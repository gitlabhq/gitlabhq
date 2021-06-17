# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsService, '#execute' do
  subject(:execute_service) { described_class.new(track, interval).execute }

  let(:track) { :create }
  let(:interval) { 1 }

  let(:frozen_time) { Time.zone.parse('23 Mar 2021 10:14:40 UTC') }
  let(:previous_action_completed_at) { frozen_time - 2.days }
  let(:current_action_completed_at) { nil }
  let(:user_can_perform_current_track_action) { true }
  let(:actions_completed) { { created_at: previous_action_completed_at, git_write_at: current_action_completed_at } }

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, email_opted_in: true) }

  before do
    travel_to(frozen_time)
    create(:onboarding_progress, namespace: group, **actions_completed)
    group.add_developer(user)
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
      :create     | 1  | { created_at: frozen_time - 2.days }
      :create     | 5  | { created_at: frozen_time - 6.days }
      :create     | 10 | { created_at: frozen_time - 11.days }
      :verify     | 1  | { created_at: frozen_time - 2.days, git_write_at: frozen_time - 2.days }
      :verify     | 5  | { created_at: frozen_time - 6.days, git_write_at: frozen_time - 6.days }
      :verify     | 10 | { created_at: frozen_time - 11.days, git_write_at: frozen_time - 11.days }
      :trial      | 1  | { created_at: frozen_time - 2.days, git_write_at: frozen_time - 2.days, pipeline_created_at: frozen_time - 2.days }
      :trial      | 5  | { created_at: frozen_time - 6.days, git_write_at: frozen_time - 6.days, pipeline_created_at: frozen_time - 6.days }
      :trial      | 10 | { created_at: frozen_time - 11.days, git_write_at: frozen_time - 11.days, pipeline_created_at: frozen_time - 11.days }
      :team       | 1  | { created_at: frozen_time - 2.days, git_write_at: frozen_time - 2.days, pipeline_created_at: frozen_time - 2.days, trial_started_at: frozen_time - 2.days }
      :team       | 5  | { created_at: frozen_time - 6.days, git_write_at: frozen_time - 6.days, pipeline_created_at: frozen_time - 6.days, trial_started_at: frozen_time - 6.days }
      :team       | 10 | { created_at: frozen_time - 11.days, git_write_at: frozen_time - 11.days, pipeline_created_at: frozen_time - 11.days, trial_started_at: frozen_time - 11.days }
      :experience | 30 | { created_at: frozen_time - 31.days, git_write_at: frozen_time - 31.days }
    end

    with_them do
      it { is_expected.to send_in_product_marketing_email(user.id, group.id, track, described_class::TRACKS[track][:interval_days].index(interval)) }
    end
  end

  context 'when initialized with a different track' do
    let(:track) { :verify }

    it { is_expected.not_to send_in_product_marketing_email }

    context 'when the previous track actions have been completed' do
      let(:current_action_completed_at) { frozen_time - 2.days }

      it { is_expected.to send_in_product_marketing_email(user.id, group.id, :verify, 0) }
    end
  end

  context 'when initialized with a different interval' do
    let(:interval) { 5 }

    it { is_expected.not_to send_in_product_marketing_email }

    context 'when the previous track action was completed within the intervals range' do
      let(:previous_action_completed_at) { frozen_time - 6.days }

      it { is_expected.to send_in_product_marketing_email(user.id, group.id, :create, 1) }
    end
  end

  context 'when the previous track action is not yet completed' do
    let(:previous_action_completed_at) { nil }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context 'when the previous track action is completed outside the intervals range' do
    let(:previous_action_completed_at) { frozen_time - 3.days }

    it { is_expected.not_to send_in_product_marketing_email }
  end

  context 'when the current track action is completed' do
    let(:current_action_completed_at) { frozen_time }

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

  describe 'do not send emails twice' do
    subject { described_class.send_for_all_tracks_and_intervals }

    let(:user) { create(:user, email_opted_in: true) }

    context 'when user already got a specific email' do
      before do
        create(:in_product_marketing_email, user: user, track: track, series: 0)
      end

      it { is_expected.not_to send_in_product_marketing_email(user.id, anything, track, 0) }
    end

    context 'when user already got sent the whole track' do
      before do
        0.upto(2) do |series|
          create(:in_product_marketing_email, user: user, track: track, series: series)
        end
      end

      it 'does not send any of the emails anymore', :aggregate_failures do
        0.upto(2) do |series|
          expect(subject).not_to send_in_product_marketing_email(user.id, anything, track, series)
        end
      end
    end

    context 'when user is in two groups' do
      let(:other_group) { create(:group) }

      before do
        other_group.add_developer(user)
      end

      context 'when both groups would get the same email' do
        before do
          create(:onboarding_progress, namespace: other_group, **actions_completed)
        end

        it 'does not send the same email twice' do
          subject

          expect(Notify).to have_received(:in_product_marketing_email).with(user.id, anything, :create, 0).once
        end
      end

      context 'when other group gets a different email' do
        before do
          create(:onboarding_progress, namespace: other_group, created_at: previous_action_completed_at, git_write_at: frozen_time - 2.days)
        end

        it 'sends both emails' do
          subject

          expect(Notify).to have_received(:in_product_marketing_email).with(user.id, group.id, :create, 0)
          expect(Notify).to have_received(:in_product_marketing_email).with(user.id, other_group.id, :verify, 0)
        end
      end
    end
  end

  it 'records sent emails' do
    expect { subject }.to change { Users::InProductMarketingEmail.count }.by(1)

    expect(
      Users::InProductMarketingEmail.where(
        user: user,
        track: Users::InProductMarketingEmail.tracks[:create],
        series: 0
      )
    ).to exist
  end

  context 'when invoked with a non existing track' do
    let(:track) { :foo }

    before do
      stub_const("#{described_class}::TRACKS", { bar: {} })
    end

    it { expect { subject }.to raise_error(ArgumentError, 'Track foo not defined') }
  end

  context 'when group is a sub-group' do
    let(:root_group) { create(:group) }
    let(:group) { create(:group) }

    before do
      group.parent = root_group
      group.save!

      allow(Ability).to receive(:allowed?).and_call_original
    end

    it 'does not raise an exception' do
      expect { execute_service }.not_to raise_error
    end
  end
end
