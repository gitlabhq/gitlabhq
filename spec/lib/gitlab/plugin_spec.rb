require 'spec_helper'

describe Gitlab::Plugin do
  describe '.execute' do
    let(:data) { Gitlab::DataBuilder::Push::SAMPLE_DATA }
    let(:plugin) { Rails.root.join('plugins', 'test.rb') }
    let(:tmp_file) { Tempfile.new('plugin-dump') }
    let(:result) { described_class.execute(plugin.to_s, data) }
    let(:success) { result.first }
    let(:message) { result.last }

    let(:plugin_source) do
      <<~EOS
        #!/usr/bin/env ruby
        x = STDIN.read
        File.write('#{tmp_file.path}', x)
      EOS
    end

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
