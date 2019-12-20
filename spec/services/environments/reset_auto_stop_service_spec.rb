# frozen_string_literal: true

require 'spec_helper'

describe Environments::ResetAutoStopService do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:reporter) { create(:user).tap { |user| project.add_reporter(user) } }
  let(:user) { developer }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject { service.execute(environment) }

    context 'when environment will be stopped automatically' do
      let(:environment) { create(:environment, :will_auto_stop, project: project) }

      it 'resets auto stop' do
        expect(environment).to receive(:reset_auto_stop).and_call_original

        expect(subject[:status]).to eq(:success)
      end

      context 'when failed to reset auto stop' do
        before do
          expect(environment).to receive(:reset_auto_stop) { false }
        end

        it 'returns error' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq('Failed to cancel auto stop because failed to update the environment.')
        end
      end

      context 'when user is reporter' do
        let(:user) { reporter }

        it 'returns error' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq('Failed to cancel auto stop because you do not have permission to update the environment.')
        end
      end
    end

    context 'when environment will not be stopped automatically' do
      let(:environment) { create(:environment, project: project) }

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq('Failed to cancel auto stop because the environment is not set as auto stop.')
      end
    end
  end
end
