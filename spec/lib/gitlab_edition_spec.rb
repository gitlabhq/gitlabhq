# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabEdition do
  def remove_instance_variable(ivar)
    described_class.remove_instance_variable(ivar) if described_class.instance_variable_defined?(ivar)
  end

  before do
    # Make sure the ENV is clean
    stub_env('FOSS_ONLY', nil)
    stub_env('EE_ONLY', nil)

    remove_instance_variable(:@is_ee)
    remove_instance_variable(:@is_jh)
  end

  after do
    remove_instance_variable(:@is_ee)
    remove_instance_variable(:@is_jh)
  end

  describe '.root' do
    it 'returns the root path of the app' do
      expect(described_class.root).to eq(Pathname.new(File.expand_path('../..', __dir__)))
    end
  end

  describe 'extensions' do
    context 'when .jh? is true' do
      before do
        allow(described_class).to receive(:jh?).and_return(true)
      end

      it 'returns %w[ee jh]' do
        expect(described_class.extensions).to match_array(%w[ee jh])
      end
    end

    context 'when .ee? is true' do
      before do
        allow(described_class).to receive(:jh?).and_return(false)
        allow(described_class).to receive(:ee?).and_return(true)
      end

      it 'returns %w[ee]' do
        expect(described_class.extensions).to match_array(%w[ee])
      end
    end

    context 'when neither .jh? and .ee? are true' do
      before do
        allow(described_class).to receive(:jh?).and_return(false)
        allow(described_class).to receive(:ee?).and_return(false)
      end

      it 'returns the extensions according to the current edition' do
        expect(described_class.extensions).to be_empty
      end
    end
  end

  describe '.ee? and .jh?' do
    def stub_path(*paths, **arguments)
      root = Pathname.new('dummy')
      pathname = double(:path, **arguments)

      allow(described_class)
        .to receive(:root)
        .and_return(root)

      allow(root).to receive(:join)

      paths.each do |path|
        allow(root)
          .to receive(:join)
          .with(path)
          .and_return(pathname)
      end
    end

    describe '.ee?' do
      context 'when EE' do
        before do
          stub_path('ee/app/models/license.rb', exist?: true)
        end

        context 'when using FOSS_ONLY=1' do
          before do
            stub_env('FOSS_ONLY', '1')
          end

          it 'returns not to be EE' do
            expect(described_class).not_to be_ee
          end
        end

        context 'when using FOSS_ONLY=0' do
          before do
            stub_env('FOSS_ONLY', '0')
          end

          it 'returns to be EE' do
            expect(described_class).to be_ee
          end
        end

        context 'when using default FOSS_ONLY' do
          it 'returns to be EE' do
            expect(described_class).to be_ee
          end
        end
      end

      context 'when CE' do
        before do
          stub_path('ee/app/models/license.rb', exist?: false)
        end

        it 'returns not to be EE' do
          expect(described_class).not_to be_ee
        end
      end
    end

    describe '.jh?' do
      context 'when JH' do
        before do
          stub_path('ee/app/models/license.rb', 'jh', exist?: true)
        end

        context 'when using default FOSS_ONLY and EE_ONLY' do
          it 'returns to be JH' do
            expect(described_class).to be_jh
          end
        end

        context 'when using FOSS_ONLY=1' do
          before do
            stub_env('FOSS_ONLY', '1')
          end

          it 'returns not to be JH' do
            expect(described_class).not_to be_jh
          end
        end

        context 'when using EE_ONLY=1' do
          before do
            stub_env('EE_ONLY', '1')
          end

          it 'returns not to be JH' do
            expect(described_class).not_to be_jh
          end
        end
      end
    end
  end
end
