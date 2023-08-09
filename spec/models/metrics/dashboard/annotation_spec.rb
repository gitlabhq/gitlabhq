# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::Annotation do
  using RSpec::Parameterized::TableSyntax

  describe 'validation' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:dashboard_path) }
    it { is_expected.to validate_presence_of(:starting_at) }
    it { is_expected.to validate_length_of(:dashboard_path).is_at_most(255) }
    it { is_expected.to validate_length_of(:panel_xid).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }

    context 'ending_at_after_starting_at' do
      where(:starting_at, :ending_at, :valid?, :message) do
        2.days.ago.beginning_of_day | 1.day.ago.beginning_of_day  | true  | nil
        1.day.ago.beginning_of_day  | nil                         | true  | nil
        1.day.ago.beginning_of_day  | 1.day.ago.beginning_of_day  | true  | nil
        1.day.ago.beginning_of_day  | 2.days.ago.beginning_of_day | false | /Ending at can't be before starting_at time/
        nil                         | 2.days.ago.beginning_of_day | false | /Starting at can't be blank/ # validation is covered by other method, be we need to assure, that ending_at_after_starting_at will not break with nil as starting_at
        nil                         | nil                         | false | /Starting at can't be blank/ # validation is covered by other method, be we need to assure, that ending_at_after_starting_at will not break with nil as starting_at
      end

      with_them do
        subject(:annotation) { build(:metrics_dashboard_annotation, starting_at: starting_at, ending_at: ending_at) }

        it do
          expect(annotation.valid?).to be(valid?)
          expect(annotation.errors.full_messages).to include(message) if message
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:nine_minutes_old_annotation) { create(:metrics_dashboard_annotation, starting_at: 9.minutes.ago) }
    let_it_be(:fifteen_minutes_old_annotation) { create(:metrics_dashboard_annotation, starting_at: 15.minutes.ago) }
    let_it_be(:just_created_annotation) { create(:metrics_dashboard_annotation) }

    describe '#after' do
      it 'returns only younger annotations' do
        expect(described_class.after(12.minutes.ago)).to match_array [nine_minutes_old_annotation, just_created_annotation]
      end
    end

    describe '#before' do
      it 'returns only older annotations' do
        expect(described_class.before(5.minutes.ago)).to match_array [fifteen_minutes_old_annotation, nine_minutes_old_annotation]
      end
    end

    describe '#for_dashboard' do
      let!(:other_dashboard_annotation) { create(:metrics_dashboard_annotation, dashboard_path: 'other_dashboard.yml') }

      it 'returns annotations only for appointed dashboard' do
        expect(described_class.for_dashboard('other_dashboard.yml')).to match_array [other_dashboard_annotation]
      end
    end

    describe '#ending_before' do
      it 'returns annotations only for appointed dashboard' do
        freeze_time do
          twelve_minutes_old_annotation = create(:metrics_dashboard_annotation, starting_at: 15.minutes.ago, ending_at: 12.minutes.ago)
          create(:metrics_dashboard_annotation, starting_at: 15.minutes.ago, ending_at: 11.minutes.ago)

          expect(described_class.ending_before(11.minutes.ago)).to match_array [fifteen_minutes_old_annotation, twelve_minutes_old_annotation]
        end
      end
    end
  end
end
