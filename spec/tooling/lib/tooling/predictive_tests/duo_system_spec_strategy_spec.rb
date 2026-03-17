# frozen_string_literal: true

require_relative '../../../../../tooling/lib/tooling/predictive_tests/duo_system_spec_strategy'
require_relative '../../../../../tooling/lib/tooling/predictive_tests/duo_test_selector'

RSpec.describe Tooling::PredictiveTests::DuoSystemSpecStrategy, feature_category: :tooling do
  let(:changed_files) { %w[app/models/user.rb app/views/users/show.html.haml] }
  let(:logger) { Logger.new(StringIO.new) }
  let(:instance) { described_class.new(changed_files: changed_files, logger: logger) }

  let(:duo_selector) { instance_double(Tooling::PredictiveTests::DuoTestSelector) }
  let(:duo_result) do
    {
      confidence: 0.9,
      specs: ['spec/features/users/profile_spec.rb', 'spec/features/admin/users_spec.rb'],
      reasoning: 'Found specs related to user views and models'
    }
  end

  before do
    allow(instance).to receive(:duo_available?).and_return(true)
    allow(Tooling::PredictiveTests::DuoTestSelector).to receive(:new).with(
      git_diff: nil,
      changed_files: nil,
      logger: logger
    ).and_return(duo_selector)
    allow(duo_selector).to receive(:select_tests).and_return(duo_result)
  end

  describe '#execute' do
    subject(:execute) { instance.execute }

    context 'when Duo CLI is available' do
      it 'returns system specs recommended by Duo' do
        expect(execute).to match_array(['spec/features/users/profile_spec.rb', 'spec/features/admin/users_spec.rb'])
      end

      it 'calls DuoTestSelector' do
        execute
        expect(Tooling::PredictiveTests::DuoTestSelector).to have_received(:new).with(git_diff: nil,
          changed_files: nil, logger: logger)
        expect(duo_selector).to have_received(:select_tests)
      end

      context 'when Duo returns low confidence' do
        let(:duo_result) do
          {
            confidence: 0.5,
            specs: [],
            reasoning: 'Large change detected'
          }
        end

        it 'returns empty array' do
          expect(execute).to be_empty
        end
      end

      context 'when DuoTestSelector raises an error' do
        before do
          allow(duo_selector).to receive(:select_tests).and_raise(StandardError, 'Duo CLI failed')
        end

        it 'returns empty array' do
          expect(execute).to be_empty
        end
      end

      describe '#confident?' do
        it 'returns false before execute is called' do
          expect(instance.confident?).to be false
        end

        it 'returns true after a successful execute' do
          instance.execute
          expect(instance.confident?).to be true
        end
      end
    end

    context 'when Duo CLI is not available' do
      before do
        allow(instance).to receive(:duo_available?).and_return(false)
      end

      it 'returns empty array' do
        expect(execute).to be_empty
      end

      it 'does not call DuoTestSelector' do
        execute
        expect(Tooling::PredictiveTests::DuoTestSelector).not_to have_received(:new)
      end
    end

    describe '#duo_available?' do
      let(:fresh_instance) { described_class.new(changed_files: changed_files, logger: logger) }

      it 'returns true when duo is on PATH' do
        allow(fresh_instance).to receive(:system).with('which duo > /dev/null 2>&1').and_return(true)
        expect(fresh_instance.send(:duo_available?)).to be true
      end

      it 'returns false when duo is not on PATH' do
        allow(fresh_instance).to receive(:system).with('which duo > /dev/null 2>&1').and_return(false)
        expect(fresh_instance.send(:duo_available?)).to be false
      end

      it 'memoizes the result of duo_available?' do
        allow(fresh_instance).to receive(:system).with('which duo > /dev/null 2>&1').and_return(true)
        fresh_instance.send(:duo_available?)
        fresh_instance.send(:duo_available?)
        expect(fresh_instance).to have_received(:system).once
      end
    end
  end
end
