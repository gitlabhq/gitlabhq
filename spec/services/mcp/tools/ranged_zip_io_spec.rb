# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::RangedZipIo, feature_category: :mcp_server do
  let(:http_io) { instance_double(Gitlab::HttpIO, eof?: true, path: nil) }

  subject(:adapter) { described_class.new(http_io) }

  it 'answers eof by delegating to eof?' do
    expect(adapter.eof).to be(true)
  end

  it 'hides path so Zip::File cannot mistake the IO for a file on disk' do
    expect(adapter.respond_to?(:path)).to be(false)
  end
end
