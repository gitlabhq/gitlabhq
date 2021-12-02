# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/lib/gitlab'

RSpec.describe 'scripts/lib/gitlab.rb' do
  let(:ee_file_path) { File.expand_path('../../../ee/app/models/license.rb', __dir__) }

  describe '.ee?' do
    before do
      stub_env('FOSS_ONLY', nil)
      allow(File).to receive(:exist?).with(ee_file_path) { true }
    end

    it 'returns true when ee/app/models/license.rb exists' do
      expect(Gitlab.ee?).to eq(true)
    end
  end

  describe '.jh?' do
    context 'when jh directory exists and EE_ONLY is not set' do
      before do
        stub_env('EE_ONLY', nil)

        allow(Dir).to receive(:exist?).with(File.expand_path('../../../jh', __dir__)) { true }
      end

      context 'when ee/app/models/license.rb exists' do
        before do
          allow(File).to receive(:exist?).with(ee_file_path) { true }
        end

        context 'when FOSS_ONLY is not set' do
          before do
            stub_env('FOSS_ONLY', nil)
          end

          it 'returns true' do
            expect(Gitlab.jh?).to eq(true)
          end
        end

        context 'when FOSS_ONLY is set to 1' do
          before do
            stub_env('FOSS_ONLY', '1')
          end

          it 'returns false' do
            expect(Gitlab.jh?).to eq(false)
          end
        end
      end

      context 'when ee/app/models/license.rb not exist' do
        before do
          allow(File).to receive(:exist?).with(ee_file_path) { false }
        end

        context 'when FOSS_ONLY is not set' do
          before do
            stub_env('FOSS_ONLY', nil)
          end

          it 'returns true' do
            expect(Gitlab.jh?).to eq(false)
          end
        end

        context 'when FOSS_ONLY is set to 1' do
          before do
            stub_env('FOSS_ONLY', '1')
          end

          it 'returns false' do
            expect(Gitlab.jh?).to eq(false)
          end
        end
      end
    end
  end
end
