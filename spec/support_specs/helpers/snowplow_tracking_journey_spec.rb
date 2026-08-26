# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/helpers/snowplow_tracking_journey'

RSpec.describe SnowplowTrackingJourney, feature_category: :onboarding do
  describe '.load' do
    it 'raises for a journey that does not exist' do
      expect { described_class.load('no_such_journey') }
        .to raise_error(ArgumentError, /No tracking journey named 'no_such_journey'/)
    end

    context 'with a journey that declares no variants' do
      it 'returns its events' do
        journey = described_class.load('invite_registration')

        expect(journey.experiment).to be_nil
        expect(journey.events).to be_present
      end

      it 'raises when a variant is passed anyway' do
        expect { described_class.load('invite_registration', variant: 'candidate') }
          .to raise_error(ArgumentError, /declares no variants/)
      end
    end

    context 'with a journey that declares variants' do
      it 'returns the events of the arm asked for, and names the experiment' do
        candidate = described_class.load('whats_new_placement', variant: 'candidate')
        control = described_class.load('whats_new_placement', variant: 'control')

        expect(candidate.experiment).to eq('whats_new_placement')
        expect(candidate.events).to be_present
        expect(candidate.events).not_to eq(control.events)
      end

      it 'raises when no variant is given' do
        expect { described_class.load('whats_new_placement') }
          .to raise_error(ArgumentError, /declares variants .*, pass one/)
      end

      it 'raises for an arm the journey does not declare' do
        expect { described_class.load('whats_new_placement', variant: 'nope') }
          .to raise_error(ArgumentError, /has no variant 'nope'/)
      end
    end
  end
end
