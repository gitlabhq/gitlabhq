# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/helpers/snowplow_event_dump'

RSpec.describe SnowplowEventDump, feature_category: :onboarding do
  let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

  let(:event_struct) { Struct.new(:event_type, :category, :action, :label, :property, keyword_init: true) }

  before do
    stub_const("#{described_class}::DIRECTORY", tmpdir)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '.write' do
    it 'takes the directory from the example id, so two examples never share one' do
      %w[1:1:1:1 1:2:1:1].each do |scoped_id|
        example = build_example(spec: 'spec/features/test_experiment_events_spec.rb', scoped_id: scoped_id)

        described_class.write(example, captured: [], raw: [])
      end

      expect(written_directories).to contain_exactly(
        'spec/features/test_experiment_events_spec/1-1-1-1',
        'spec/features/test_experiment_events_spec/1-2-1-1'
      )
    end

    it 'keeps specs that share a basename apart' do
      ['spec/features/invite_flow_spec.rb', 'ee/spec/features/invite_flow_spec.rb'].each do |spec|
        described_class.write(build_example(spec: spec), captured: [], raw: [])
      end

      expect(written_directories).to contain_exactly(
        'spec/features/invite_flow_spec/1-1',
        'ee/spec/features/invite_flow_spec/1-1'
      )
    end

    it 'writes one entry per distinct event, without the fields it did not carry' do
      captured = [
        event(category: 'test:index', action: 'click_test_button', label: 'sidebar'),
        event(category: 'test:index', action: 'click_test_button', label: 'sidebar'),
        event(category: 'test_experiment', action: 'assignment', property: 'candidate')
      ]

      described_class.write(build_example, captured: captured, raw: [])

      expect(written_events).to eq([
        { 'category' => 'test:index', 'action' => 'click_test_button', 'label' => 'sidebar' },
        { 'category' => 'test_experiment', 'action' => 'assignment', 'property' => 'candidate' }
      ])
    end

    it 'counts the events a contract has no way to express' do
      captured = [event(type: 'pv'), event(type: 'pv'), event(type: 'ue'), event(action: 'assignment')]

      described_class.write(build_example, captured: captured, raw: [])

      expect(written('events.yml').read)
        .to include('not expressible in a contract: 2 page views, 1 self-describing event')
    end

    it 'says nothing about other event types when there were none' do
      described_class.write(build_example, captured: [event(action: 'assignment')], raw: [])

      expect(written('events.yml').read).not_to include('Also captured')
    end

    it 'writes the payloads as they would have been posted' do
      raw = [{ 'e' => 'se', 'se_ac' => 'assignment' }]

      described_class.write(build_example, captured: [], raw: raw)

      expect(Gitlab::Json::SafeParser.parse(written('payloads.json').read)).to eq(raw)
    end

    it 'replaces what an earlier run left behind rather than adding to it' do
      described_class.write(build_example, captured: [], raw: [])
      stale = written('events.yml').dirname.join('stale.json')
      stale.write('{}')

      described_class.write(build_example, captured: [], raw: [])

      expect(stale).not_to exist
    end

    describe 'the manifest' do
      it 'points at the dump by the journey and variant it proves' do
        example = build_example(
          spec: 'spec/features/test_experiment_events_spec.rb',
          scoped_id: '1:1:1:1',
          journey: { name: 'test_experiment', variant: 'candidate' }
        )

        described_class.write(example, captured: [], raw: [])

        expect(manifest).to contain_exactly(a_hash_including(
          'journey' => 'test_experiment',
          'variant' => 'candidate',
          'events' => 'spec/features/test_experiment_events_spec/1-1-1-1/events.yml',
          'payloads' => 'spec/features/test_experiment_events_spec/1-1-1-1/payloads.json'
        ))
      end

      it 'lists an entry per example when several prove the same journey' do
        %w[1:1 1:2].each do |scoped_id|
          example = build_example(scoped_id: scoped_id, journey: { name: 'test_flow' })

          described_class.write(example, captured: [], raw: [])
        end

        expect(manifest.pluck('events')).to contain_exactly(
          'spec/features/test_flow_spec/1-1/events.yml',
          'spec/features/test_flow_spec/1-2/events.yml'
        )
        expect(manifest.pluck('journey')).to all(eq('test_flow'))
      end

      it 'records no journey for an example that captured without asserting one' do
        described_class.write(build_example, captured: [], raw: [])

        expect(manifest.first).to include('journey' => nil, 'variant' => nil)
      end

      it 'replaces the entry when the same example is run again' do
        2.times do
          described_class.write(build_example(journey: { name: 'test_flow' }), captured: [], raw: [])
        end

        expect(manifest.size).to eq(1)
      end

      it 'drops entries whose dump is no longer on disk' do
        described_class.write(build_example(scoped_id: '1:1'), captured: [], raw: [])
        FileUtils.rm_rf(tmpdir.join('spec/features/test_flow_spec/1-1'))

        described_class.write(build_example(scoped_id: '1:2'), captured: [], raw: [])

        expect(manifest.pluck('events')).to contain_exactly('spec/features/test_flow_spec/1-2/events.yml')
      end
    end
  end

  def event(type: 'se', **attributes)
    event_struct.new(event_type: type, **attributes)
  end

  def build_example(
    description: 'emits the events', spec: 'spec/features/test_flow_spec.rb', scoped_id: '1:1', journey: nil)
    instance_double(
      RSpec::Core::Example,
      id: "./#{spec}[#{scoped_id}]",
      metadata: { snowplow_tracking_journey: journey }.compact,
      full_description: "Test flow #{description}",
      location: "./#{spec}:1",
      description: description
    )
  end

  def written_directories
    tmpdir.glob('**/events.yml').map { |path| path.dirname.relative_path_from(tmpdir).to_s }
  end

  def written(filename)
    tmpdir.glob("**/#{filename}").first
  end

  def written_events
    YAML.safe_load(written('events.yml').read).fetch('events')
  end

  def manifest
    Gitlab::Json::SafeParser.parse(tmpdir.join('index.json').read)
  end
end
