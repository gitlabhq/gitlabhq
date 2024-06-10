# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::App::RedisVersionCheck, :silence_stdout, feature_category: :shared do
  let(:checker) { described_class.new }

  describe '#check?' do
    using RSpec::Parameterized::TableSyntax

    where(:info, :expected, :message) do
      { 'redis_version' => nil } | false |
        "Could not retrieve the Redis version. Please check if your settings are correct"
      { 'redis_version' => '5.9.0' } | false |
        ("Your Redis version 5.9.0 is not supported anymore. " \
          "Update your Redis server to a version >= #{described_class::RECOMMENDED_REDIS_VERSION}")
      { 'redis_version' => '6.0.0' } | false |
        ("Your Redis version 6.0.0 has reached end-of-life (EOL). " \
          "Update your Redis server to a version >= #{described_class::RECOMMENDED_REDIS_VERSION}")
      { 'redis_version' => '6.2.14' } | true | nil
    end

    with_them do
      it do
        Gitlab::Redis::Queues.with do |redis|
          allow(redis).to receive(:info).and_return(info)
        end

        expect(checker.check?).to eq(expected)
        expect(checker.instance_variable_get(:@custom_error_message)).to eq(message)
      end
    end
  end
end
