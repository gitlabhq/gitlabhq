# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Monitor::DemoProjects do
  describe '#primary_keys' do
    subject { described_class.primary_keys }

    it 'fetches primary_keys when on SaaS', :saas do
      allow(Gitlab).to receive(:staging?).and_return(false)

      expect(subject).to eq(Gitlab::Monitor::DemoProjects::DOT_COM_IDS)
    end

    it 'fetches primary_keys when on staging', :saas do
      allow(Gitlab).to receive(:staging?).and_return(true)

      expect(subject).to eq(Gitlab::Monitor::DemoProjects::STAGING_IDS)
    end

    it 'fetches all keys when in the dev or test env' do
      project = create(:project)
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)

      expect(subject).to eq([project.id])
    end

    it 'falls back on empty array' do
      stub_config_setting(url: 'https://helloworld')
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      expect(subject).to eq([])
    end
  end
end
