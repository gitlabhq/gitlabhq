# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JsonLogger do
  subject { described_class.new('/dev/null') }

  it_behaves_like 'a json logger', {}

  describe '#file_name' do
    let(:subclass) do
      Class.new(Gitlab::JsonLogger) do
        def self.file_name_noext
          'testlogger'
        end
      end
    end

    it 'raises error when file_name_noext not implemented' do
      expect { described_class.file_name }.to raise_error(
        'JsonLogger implementations must provide file_name_noext implementation'
      )
    end

    it 'returns log file name when file_name_noext is implemented' do
      expect(subclass.file_name).to eq('testlogger.log')
    end
  end
end
