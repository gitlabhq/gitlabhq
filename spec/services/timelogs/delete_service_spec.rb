# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelogs::DeleteService, feature_category: :team_planning do
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:timelog) { create(:timelog, user: author, issue: issue, time_spent: 1800) }

  let(:service) { described_class.new(timelog, user) }

  describe '#execute' do
    subject { service.execute }

    context 'when the timelog exists' do
      let(:user) { author }

      it 'removes the timelog' do
        expect { subject }.to change { Timelog.count }.by(-1)
      end

      it 'returns the removed timelog' do
        is_expected.to be_success
        expect(subject.payload[:timelog]).to eq(timelog)
      end
    end

    context 'when the timelog does not exist' do
      let(:user) { create(:user) }
      let!(:timelog) { nil }

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Timelog doesn\'t exist or you don\'t have permission to delete it')
        expect(subject.http_status).to eq(404)
      end
    end

    context 'when the user does not have permission' do
      let(:user) { create(:user) }

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Timelog doesn\'t exist or you don\'t have permission to delete it')
        expect(subject.http_status).to eq(404)
      end
    end

    context 'when the timelog deletion fails' do
      let(:user) { author }
      let!(:timelog) { create(:timelog, user: author, issue: issue, time_spent: 1800) }

      before do
        allow(timelog).to receive(:destroy).and_return(false)
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Failed to remove timelog')
        expect(subject.http_status).to eq(400)
      end
    end
  end
end
