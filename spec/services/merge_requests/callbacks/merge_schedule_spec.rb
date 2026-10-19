# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Callbacks::MergeSchedule, feature_category: :code_review_workflow do
  let_it_be_with_reload(:merge_request) { create(:merge_request) }

  let(:params) { {} }
  let(:current_user) { merge_request.author }
  let(:callback) { described_class.new(issuable: merge_request, current_user: current_user, params: params) }

  describe '#after_initialize' do
    subject(:after_initialize) { callback.after_initialize }

    context 'when merge_after is provided' do
      let(:params) { { merge_after: '2024-11-07T19:17+0200' } }

      it 'builds a merge_schedule with merge_after set' do
        after_initialize

        expect(merge_request.merge_schedule).to be_present
        expect(merge_request.merge_schedule.merge_after).to eq(Time.zone.parse('2024-11-07T19:17+0200'))
      end

      it 'leaves merge_before nil' do
        after_initialize

        expect(merge_request.merge_schedule.merge_before).to be_nil
      end
    end

    context 'when only merge_before is provided' do
      let(:params) { { merge_before: '2024-11-08T10:00+0200' } }

      it 'creates model validation errors' do
        after_initialize

        expect(merge_request.merge_schedule).to be_present
        expect(merge_request.merge_schedule).not_to be_valid
        expect(merge_request.merge_schedule.errors[:merge_after]).to include("can't be blank")
      end
    end

    context 'when both merge_after and merge_before are provided' do
      let(:params) { { merge_after: '2024-11-07T19:17+0200', merge_before: '2024-11-08T10:00+0200' } }

      it 'builds a single merge_schedule with both fields set', :aggregate_failures do
        after_initialize

        expect(merge_request.merge_schedule.merge_after).to eq(Time.zone.parse('2024-11-07T19:17+0200'))
        expect(merge_request.merge_schedule.merge_before).to eq(Time.zone.parse('2024-11-08T10:00+0200'))
      end

      context 'when merge_before is before merge_after' do
        let(:params) { { merge_after: '2024-11-08T10:00+0200', merge_before: '2024-11-07T19:17+0200' } }

        it 'creates model validation errors', :aggregate_failures do
          after_initialize

          expect(merge_request.merge_schedule).to be_present
          expect(merge_request.merge_schedule).not_to be_valid
          expect(merge_request.merge_schedule.errors[:merge_before]).to include("must be after the start time")
        end
      end
    end

    context 'when updating an existing schedule' do
      before do
        merge_request.create_merge_schedule(
          merge_after: '2024-11-07T19:17+0200',
          merge_before: '2024-11-08T10:00+0200'
        )
        merge_request.reload
      end

      context 'when only merge_after is provided' do
        let(:params) { { merge_after: '2024-11-07T20:00+0000' } }

        it 'updates merge_after and preserves the existing merge_before', :aggregate_failures do
          after_initialize

          expect(merge_request.merge_schedule.merge_after).to eq(Time.zone.parse('2024-11-07T20:00+0000'))
          expect(merge_request.merge_schedule.merge_before).to eq(Time.zone.parse('2024-11-08T10:00+0200'))
        end
      end

      context 'when only merge_before is provided' do
        let(:params) { { merge_before: '2024-11-09T12:00+0000' } }

        it 'updates merge_before and preserves the existing merge_after', :aggregate_failures do
          after_initialize

          expect(merge_request.merge_schedule.merge_after).to eq(Time.zone.parse('2024-11-07T19:17+0200'))
          expect(merge_request.merge_schedule.merge_before).to eq(Time.zone.parse('2024-11-09T12:00+0000'))
        end
      end

      context 'when merge_after is explicitly set to nil' do
        let(:params) { { merge_after: nil, merge_before: '2024-11-09T12:00+0000' } }

        it 'creates model validation errors', :aggregate_failures do
          after_initialize

          expect(merge_request.merge_schedule).not_to be_marked_for_destruction
          expect(merge_request.merge_schedule).not_to be_valid
          expect(merge_request.merge_schedule.errors[:merge_after]).to include("can't be blank")
        end
      end

      context 'when merge_before is explicitly set to nil' do
        let(:params) { { merge_after: '2024-11-07T20:00+0000', merge_before: nil } }

        it 'clears merge_before and updates merge_after', :aggregate_failures do
          after_initialize

          expect(merge_request.merge_schedule.merge_after).to eq(Time.zone.parse('2024-11-07T20:00+0000'))
          expect(merge_request.merge_schedule.merge_before).to be_nil
        end
      end

      context 'when both are explicitly set to nil' do
        let(:params) { { merge_after: nil, merge_before: nil } }

        it 'marks the existing merge_schedule for destruction' do
          after_initialize

          expect(merge_request.merge_schedule).to be_marked_for_destruction
        end
      end
    end

    context 'when neither merge_after nor merge_before is provided' do
      let(:params) { {} }

      it 'does not build a merge_schedule' do
        after_initialize

        expect(merge_request.merge_schedule).to be_nil
      end

      context 'when a merge_schedule already exists' do
        before do
          merge_request.create_merge_schedule(merge_after: '2024-11-07T19:17+0200')
          merge_request.reload
        end

        it 'does not mark the existing schedule for destruction' do
          after_initialize

          expect(merge_request.merge_schedule).not_to be_marked_for_destruction
        end
      end
    end
  end
end
