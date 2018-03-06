require 'spec_helper'

describe Gitlab::Database::Median do
  let(:dummy_class) do
    Class.new do
      include Gitlab::Database::Median
    end
  end

  subject(:median) { dummy_class.new }

  describe '#median_datetimes' do
    it 'raises NotSupportedError', :mysql do
      expect { median.median_datetimes(nil, nil, nil, :project_id) }.to raise_error(dummy_class::NotSupportedError, "partition_column is not supported for MySQL")
    end
  end
end
