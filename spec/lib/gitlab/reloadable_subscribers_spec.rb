# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ReloadableSubscribers, feature_category: :observability do
  let(:dir) { Dir.mktmpdir }
  let(:subscriber_file) { File.join(dir, 'reloadable_subscribers_spec_subscriber.rb') }
  let(:loader) do
    Zeitwerk::Loader.new.tap do |loader|
      loader.push_dir(dir)
      loader.enable_reloading
    end
  end

  let(:subscriber_source) do
    <<~RUBY
      class ReloadableSubscribersSpecSubscriber < ActiveSupport::Subscriber
        attach_to :reloadable_subscribers_spec

        def ping(event)
          ReloadableSubscribersSpecEvents << event.name
        end
      end
    RUBY
  end

  # Matched by name because every reload creates a new class object.
  def attached
    ActiveSupport::Subscriber.subscribers.select do |subscriber|
      subscriber.class.name.to_s == 'ReloadableSubscribersSpecSubscriber'
    end
  end

  def subscriber_class
    Object.const_get(:ReloadableSubscribersSpecSubscriber, false)
  end

  def reload
    names = described_class.detach(loader)
    loader.reload
    described_class.reattach(names)
  end

  before do
    stub_const('ReloadableSubscribersSpecEvents', [])
    File.write(subscriber_file, subscriber_source)
    loader.setup
    subscriber_class
  end

  after do
    described_class.detach(loader)
    loader.unload
    loader.unregister
    FileUtils.remove_entry(dir)
  end

  it 'keeps a single subscriber, built from the reloaded class, across reloads' do
    2.times { reload }

    ActiveSupport::Notifications.instrument('ping.reloadable_subscribers_spec')

    expect(ReloadableSubscribersSpecEvents).to eq(['ping.reloadable_subscribers_spec'])
    expect(attached)
      .to contain_exactly(an_instance_of(subscriber_class))
  end

  describe '.detach' do
    it 'returns the names of the detached subscribers once each' do
      subscriber_class.attach_to(:reloadable_subscribers_spec_other)

      expect(described_class.detach(loader)).to eq(['ReloadableSubscribersSpecSubscriber'])
      expect(attached).to be_empty
    end

    it 'keeps subscribers the loader does not manage' do
      stub_const('ReloadableSubscribersSpecOther', Class.new(ActiveSupport::Subscriber) do
        def ping(event)
          ReloadableSubscribersSpecEvents << event.name
        end
      end)
      anonymous = Class.new(ActiveSupport::Subscriber)

      ReloadableSubscribersSpecOther.attach_to(:reloadable_subscribers_spec_other)
      anonymous.attach_to(:reloadable_subscribers_spec_anonymous)

      described_class.detach(loader)
      ActiveSupport::Notifications.instrument('ping.reloadable_subscribers_spec_other')

      expect(ReloadableSubscribersSpecEvents).to eq(['ping.reloadable_subscribers_spec_other'])
      expect(ActiveSupport::Subscriber.subscribers).to include(an_instance_of(anonymous))
    ensure
      ReloadableSubscribersSpecOther.detach_from(:reloadable_subscribers_spec_other)
      anonymous.detach_from(:reloadable_subscribers_spec_anonymous)
    end
  end

  describe '.reattach' do
    it 'tracks the error when a subscriber class fails to load' do
      names = described_class.detach(loader)
      File.write(subscriber_file, 'class ReloadableSubscribersSpecSubscriber <')
      loader.reload

      expect(Gitlab::ErrorTracking).to receive(:track_exception)
        .with(an_instance_of(SyntaxError), subscriber: 'ReloadableSubscribersSpecSubscriber')

      expect { described_class.reattach(names) }.not_to raise_error
      expect(attached).to be_empty
    end
  end
end
