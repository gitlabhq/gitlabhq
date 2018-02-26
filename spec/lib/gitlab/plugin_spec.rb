require 'spec_helper'

describe Gitlab::Plugin do
  describe '.execute' do
    let(:data) { Gitlab::DataBuilder::Push::SAMPLE_DATA }
    let(:plugin) { Rails.root.join('plugins', 'test.rb') }
    let(:tmp_file) { Tempfile.new('plugin-dump').path }

    before do
      File.write(plugin, plugin_source)
      File.chmod(0o777, plugin)
    end

    after do
      FileUtils.rm(plugin)
      FileUtils.rm(tmp_file)
    end

    subject { described_class.execute(plugin.to_s, data) }

    it { is_expected.to be true }

    it 'ensures plugin received data via stdin' do
      subject

      expect(File.read(tmp_file)).to eq(data.to_json)
    end
  end

  private

  def plugin_source
    <<-EOS
#!/usr/bin/env ruby
x = STDIN.read
File.write('#{tmp_file}', x)
    EOS
  end
end
