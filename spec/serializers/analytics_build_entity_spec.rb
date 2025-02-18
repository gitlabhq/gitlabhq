# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AnalyticsBuildEntity do
  let(:entity) do
    described_class.new(build, request: double)
  end

  context 'build with an author' do
    let(:user) { create(:user) }
    let(:started_at) { 2.hours.ago }
    let(:finished_at) { 1.hour.ago }
    let(:build) { create(:ci_build, author: user, started_at: started_at, finished_at: finished_at) }

    subject { entity.as_json }

    around do |example|
      freeze_time { example.run }
    end

    it 'contains the URL' do
      expect(subject).to include(:url)
    end

    it 'contains the author' do
      expect(subject).to include(:author)
    end

    it 'contains the project path' do
      expect(subject).to include(:project_path)
    end

    it 'contains the namespace full path' do
      expect(subject).to include(:namespace_full_path)
    end

    it 'does not contain sensitive information' do
      expect(subject).not_to include(/token/)
      expect(subject).not_to include(/variables/)
    end

    it 'contains the right started at' do
      expect(subject[:date]).to eq('about 2 hours ago')
    end

    it 'contains the duration' do
      expect(subject[:total_time]).to eq(hours: 1)
    end

    context 'no started at or finished at date' do
      let(:started_at) { nil }
      let(:finished_at) { nil }

      it 'does not blow up' do
        expect { subject[:date] }.not_to raise_error
      end

      it 'shows the right message' do
        expect(subject[:date]).to eq('Not started')
      end

      it 'shows the right total time' do
        expect(subject[:total_time]).to eq({})
      end
    end

    context 'no started at date' do
      let(:started_at) { nil }

      it 'does not blow up' do
        expect { subject[:date] }.not_to raise_error
      end

      it 'shows the right message' do
        expect(subject[:date]).to eq('Not started')
      end

      it 'shows the right total time' do
        expect(subject[:total_time]).to eq({})
      end
    end

    context 'no finished at date' do
      let(:finished_at) { nil }

      it 'does not blow up' do
        expect { subject[:date] }.not_to raise_error
      end

      it 'shows the right message' do
        expect(subject[:date]).to eq('about 2 hours ago')
      end

      it 'shows the right total time' do
        expect(subject[:total_time]).to eq({ hours: 2 })
      end
    end
  end
end
