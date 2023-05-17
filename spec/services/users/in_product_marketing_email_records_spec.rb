# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::InProductMarketingEmailRecords, feature_category: :onboarding do
  let_it_be(:user) { create :user }

  subject(:records) { described_class.new }

  it 'initializes records' do
    expect(subject.records).to match_array []
  end

  describe '#save!' do
    before do
      allow(Users::InProductMarketingEmail).to receive(:bulk_insert!)

      records.add(user, track: :team_short, series: 0)
      records.add(user, track: :create, series: 1)
      records.add(user, campaign: Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE)
    end

    it 'bulk inserts added records' do
      expect(Users::InProductMarketingEmail).to receive(:bulk_insert!).with(records.records)
      records.save!
    end

    it 'resets its records' do
      records.save!
      expect(records.records).to match_array []
    end
  end

  describe '#add' do
    it 'adds a Users::InProductMarketingEmail record to its records', :aggregate_failures do
      freeze_time do
        records.add(user, track: :team_short, series: 0)
        records.add(user, track: :create, series: 1)
        records.add(user, campaign: Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE)

        first, second, third = records.records

        expect(first).to be_a Users::InProductMarketingEmail
        expect(first.campaign).to be_nil
        expect(first.track.to_sym).to eq :team_short
        expect(first.series).to eq 0
        expect(first.created_at).to eq Time.zone.now
        expect(first.updated_at).to eq Time.zone.now

        expect(second).to be_a Users::InProductMarketingEmail
        expect(second.campaign).to be_nil
        expect(second.track.to_sym).to eq :create
        expect(second.series).to eq 1
        expect(second.created_at).to eq Time.zone.now
        expect(second.updated_at).to eq Time.zone.now

        expect(third).to be_a Users::InProductMarketingEmail
        expect(third.campaign).to eq Users::InProductMarketingEmail::BUILD_IOS_APP_GUIDE
        expect(third.track).to be_nil
        expect(third.series).to be_nil
        expect(third.created_at).to eq Time.zone.now
        expect(third.updated_at).to eq Time.zone.now
      end
    end
  end
end
