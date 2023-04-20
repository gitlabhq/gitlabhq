# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::ConvertToBigint, feature_category: :database do
  describe 'com_or_dev_or_test_but_not_jh?' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :jh, :expectation) do
      true  | true  | true  | true
      true  | false | true  | false
      false | true  | true  | true
      false | false | true  | false
      true  | true  | false | true
      true  | false | false | true
      false | true  | false | true
      false | false | false | false
    end

    with_them do
      it 'returns true for GitLab.com (but not JH), dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)
        allow(Gitlab).to receive(:jh?).and_return(jh)

        migration = Class
          .new
          .include(Gitlab::Database::MigrationHelpers::ConvertToBigint)
          .new

        expect(migration.com_or_dev_or_test_but_not_jh?).to eq(expectation)
      end
    end
  end
end
