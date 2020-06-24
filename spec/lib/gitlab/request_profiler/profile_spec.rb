# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::RequestProfiler::Profile do
  let(:profile) { described_class.new(filename) }

  describe '.new' do
    context 'using old filename' do
      let(:filename) { '|api|v4|version.txt_1562854738.html' }

      it 'returns valid data' do
        expect(profile).to be_valid
        expect(profile.request_path).to eq('/api/v4/version.txt')
        expect(profile.time).to eq(Time.at(1562854738).utc)
        expect(profile.type).to eq('html')
      end
    end

    context 'using new filename' do
      let(:filename) { '|api|v4|version.txt_1563547949_execution.html' }

      it 'returns valid data' do
        expect(profile).to be_valid
        expect(profile.request_path).to eq('/api/v4/version.txt')
        expect(profile.profile_mode).to eq('execution')
        expect(profile.time).to eq(Time.at(1563547949).utc)
        expect(profile.type).to eq('html')
      end
    end
  end

  describe '#content_type' do
    context 'when using html file' do
      let(:filename) { '|api|v4|version.txt_1562854738_memory.html' }

      it 'returns valid data' do
        expect(profile).to be_valid
        expect(profile.content_type).to eq('text/html')
      end
    end

    context 'when using text file' do
      let(:filename) { '|api|v4|version.txt_1562854738_memory.txt' }

      it 'returns valid data' do
        expect(profile).to be_valid
        expect(profile.content_type).to eq('text/plain')
      end
    end

    context 'when file is unknown' do
      let(:filename) { '|api|v4|version.txt_1562854738_memory.xxx' }

      it 'returns valid data' do
        expect(profile).not_to be_valid
        expect(profile.content_type).to be_nil
      end
    end
  end
end
