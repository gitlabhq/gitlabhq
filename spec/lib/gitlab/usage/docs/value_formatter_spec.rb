# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Docs::ValueFormatter do
  describe '.format' do
    using RSpec::Parameterized::TableSyntax
    where(:key, :value, :expected_value) do
      :product_group     | 'growth::product intelligence' | '`growth::product intelligence`'
      :data_source       | 'redis'                        | 'Redis'
      :data_source       | 'ruby'                         | 'Ruby'
      :introduced_by_url | 'http://test.com'              | '[Introduced by](http://test.com)'
      :tier              | %w(gold premium)               | ' `gold`, `premium`'
      :distribution      | %w(ce ee)                      | ' `ce`, `ee`'
      :key_path          | 'key.path'                     | '**`key.path`**'
      :milestone         | '13.4'                         | '13.4'
      :status            | 'data_available'               | '`data_available`'
    end

    with_them do
      subject { described_class.format(key, value) }

      it { is_expected.to eq(expected_value) }
    end
  end
end
