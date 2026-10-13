# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'

require_relative '../../support/helpers/snowplow_tracking_journey'

RSpec.describe SnowplowTrackingJourney, feature_category: :onboarding do
  let(:directory) { Pathname.new(Dir.mktmpdir) }

  before do
    stub_const('SnowplowTrackingJourney::DIRECTORY', directory)
  end

  after do
    FileUtils.rm_rf(directory)
  end

  def write_journey(name, contents)
    File.write(directory.join("#{name}.yml"), contents.to_yaml)
  end

  describe '.load' do
    it 'raises for a journey that does not exist' do
      expect { described_class.load('no_such_journey') }
        .to raise_error(ArgumentError, /No tracking journey named 'no_such_journey'/)
    end

    context 'with a journey that declares no variants' do
      before do
        write_journey('plain_journey', { 'events' => [{ 'action' => 'register' }] })
      end

      it 'returns its events' do
        journey = described_class.load('plain_journey')

        expect(journey.experiment).to be_nil
        expect(journey.events).to eq([{ 'action' => 'register' }])
      end

      it 'raises when a variant is passed anyway' do
        expect { described_class.load('plain_journey', variant: 'candidate') }
          .to raise_error(ArgumentError, /declares no variants/)
      end
    end

    context 'with a journey that declares variants' do
      before do
        write_journey('varied_journey', {
          'experiment' => 'my_experiment',
          'variants' => {
            'candidate' => { 'events' => [{ 'action' => 'click_candidate' }] },
            'control' => { 'events' => [{ 'action' => 'click_control' }] }
          }
        })
      end

      it 'returns the events of the arm asked for, and names the experiment' do
        candidate = described_class.load('varied_journey', variant: 'candidate')
        control = described_class.load('varied_journey', variant: 'control')

        expect(candidate.experiment).to eq('my_experiment')
        expect(candidate.events).to eq([{ 'action' => 'click_candidate' }])
        expect(candidate.events).not_to eq(control.events)
      end

      it 'raises when no variant is given' do
        expect { described_class.load('varied_journey') }
          .to raise_error(ArgumentError, /declares variants .*, pass one/)
      end

      it 'raises for an arm the journey does not declare' do
        expect { described_class.load('varied_journey', variant: 'nope') }
          .to raise_error(ArgumentError, /has no variant 'nope'/)
      end
    end
  end
end
