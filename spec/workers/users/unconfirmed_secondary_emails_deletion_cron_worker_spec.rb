# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UnconfirmedSecondaryEmailsDeletionCronWorker, feature_category: :user_management do
  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    it 'deletes unconfirmed secondary emails created before the cutoff', :aggregate_failures, :freeze_time do
      cut_off = ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago

      unconfirmed_secondary_email_created_before_cut_off_1 = create(
        :email,
        created_at: cut_off - 1.second
      )

      unconfirmed_secondary_email_created_before_cut_off_2 = create(
        :email,
        created_at: cut_off - 1.day
      )

      unconfirmed_secondary_email_created_at_cut_off = create(
        :email,
        created_at: cut_off
      )

      unconfirmed_secondary_email_created_after_cut_off_1 = create(
        :email,
        created_at: cut_off + 1.second
      )

      unconfirmed_secondary_email_created_after_cut_off_2 = create(
        :email,
        created_at: cut_off + 1.day
      )

      confirmed_secondary_email_created_before_cut_off_1 = create(
        :email,
        :confirmed,
        created_at: cut_off - 1.second
      )

      confirmed_secondary_email_created_before_cut_off_2 = create(
        :email,
        :confirmed,
        created_at: cut_off - 1.day
      )

      confirmed_secondary_email_created_at_cut_off = create(
        :email,
        :confirmed,
        created_at: cut_off
      )

      confirmed_secondary_email_created_after_cut_off_1 = create(
        :email,
        :confirmed,
        created_at: cut_off + 1.second
      )

      confirmed_secondary_email_created_after_cut_off_2 = create(
        :email,
        :confirmed,
        created_at: cut_off + 1.day
      )

      expect { worker.perform }.to change { Email.count }.by(-2)

      expect(Email.exists?(unconfirmed_secondary_email_created_before_cut_off_1.id)).to eq(false)
      expect(Email.exists?(unconfirmed_secondary_email_created_before_cut_off_2.id)).to eq(false)
      expect(Email.exists?(unconfirmed_secondary_email_created_at_cut_off.id)).to eq(true)
      expect(Email.exists?(unconfirmed_secondary_email_created_after_cut_off_1.id)).to eq(true)
      expect(Email.exists?(unconfirmed_secondary_email_created_after_cut_off_2.id)).to eq(true)

      expect(Email.exists?(confirmed_secondary_email_created_before_cut_off_1.id)).to eq(true)
      expect(Email.exists?(confirmed_secondary_email_created_before_cut_off_2.id)).to eq(true)
      expect(Email.exists?(confirmed_secondary_email_created_at_cut_off.id)).to eq(true)
      expect(Email.exists?(confirmed_secondary_email_created_after_cut_off_1.id)).to eq(true)
      expect(Email.exists?(confirmed_secondary_email_created_after_cut_off_2.id)).to eq(true)
    end
  end
end
