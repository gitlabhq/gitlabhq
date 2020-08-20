# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Template::MetricsDashboardTemplate do
  subject { described_class }

  describe '.all' do
    it 'combines the globals and rest' do
      all = subject.all.map(&:name)

      expect(all).to include('Default')
    end
  end

  describe '#content' do
    it 'loads the full file' do
      example_dashboard = subject.new(Rails.root.join('lib/gitlab/metrics/templates/Default.metrics-dashboard.yml'))

      expect(example_dashboard.name).to eq 'Default'
      expect(example_dashboard.content).to start_with('#')
    end
  end

  it_behaves_like 'file template shared examples', 'Default', '.metrics-dashboard.yml'
end
