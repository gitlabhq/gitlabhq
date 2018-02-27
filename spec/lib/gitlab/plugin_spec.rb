require 'spec_helper'

describe Gitlab::Plugin do
  describe '.execute' do
    let(:data) { Gitlab::DataBuilder::Push::SAMPLE_DATA }
    let(:plugin) { Rails.root.join('plugins', 'test.rb') }
    let(:tmp_file) { Tempfile.new('plugin-dump') }

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

    subject { described_class.execute(plugin.to_s, data) }

    context 'successful execution' do
      before do
        File.chmod(0o777, plugin)
      end

      after do
        tmp_file.close!
      end

      it { is_expected.to be true }

      it 'ensures plugin received data via stdin' do
        subject

        expect(File.read(tmp_file.path)).to eq(data.to_json)
      end
    end

    context 'non-executable' do
      it { is_expected.to be false }
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

      it { is_expected.to be false }
    end
  end
end
