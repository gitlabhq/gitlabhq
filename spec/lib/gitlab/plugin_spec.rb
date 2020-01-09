# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Plugin do
  let(:plugin) { Rails.root.join('plugins', 'test.rb') }
  let(:tmp_file) { Tempfile.new('plugin-dump') }

  let(:plugin_source) do
    <<~EOS
      #!/usr/bin/env ruby
      x = STDIN.read
      File.write('#{tmp_file.path}', x)
    EOS
  end

  context 'with plugins present' do
    before do
      File.write(plugin, plugin_source)
    end

    after do
      FileUtils.rm(plugin)
    end

    describe '.any?' do
      it 'returns true' do
        expect(described_class.any?).to be true
      end
    end

    describe '.files?' do
      it 'returns a list of plugins' do
        expect(described_class.files).to match_array([plugin.to_s])
      end
    end
  end

  context 'without any plugins' do
    describe '.any?' do
      it 'returns false' do
        expect(described_class.any?).to be false
      end
    end

    describe '.files' do
      it 'returns an empty list' do
        expect(described_class.files).to be_empty
      end
    end
  end

  describe '.execute' do
    let(:data) { Gitlab::DataBuilder::Push::SAMPLE_DATA }
    let(:result) { described_class.execute(plugin.to_s, data) }
    let(:success) { result.first }
    let(:message) { result.last }

    before do
      File.write(plugin, plugin_source)
    end

    after do
      FileUtils.rm(plugin)
    end

    context 'successful execution' do
      before do
        File.chmod(0o777, plugin)
      end

      after do
        tmp_file.close!
      end

      it { expect(success).to be true }
      it { expect(message).to be_empty }

      it 'ensures plugin received data via stdin' do
        result

        expect(File.read(tmp_file.path)).to eq(data.to_json)
      end
    end

    context 'non-executable' do
      it { expect(success).to be false }
      it { expect(message).to include('Permission denied') }
    end

    context 'non-zero exit' do
      let(:plugin_source) do
        <<~EOS
          #!/usr/bin/env ruby
          exit 1
        EOS
      end

      before do
        File.chmod(0o777, plugin)
      end

      it { expect(success).to be false }
      it { expect(message).to be_empty }
    end
  end
end
