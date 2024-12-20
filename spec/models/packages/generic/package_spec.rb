# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Generic::Package, type: :model, feature_category: :package_registry do
  describe 'validations' do
    describe '#name' do
      it { is_expected.to allow_value('123').for(:name) }
      it { is_expected.to allow_value('foo').for(:name) }
      it { is_expected.to allow_value('foo.bar.baz-2.0-20190901.47283-1').for(:name) }
      it { is_expected.not_to allow_value('../../foo').for(:name) }
      it { is_expected.not_to allow_value('..\..\foo').for(:name) }
      it { is_expected.not_to allow_value('%2f%2e%2e%2f%2essh%2fauthorized_keys').for(:name) }
      it { is_expected.not_to allow_value('$foo/bar').for(:name) }
      it { is_expected.not_to allow_value('my file name').for(:name) }
      it { is_expected.not_to allow_value('!!().for(:name)().for(:name)').for(:name) }
    end

    describe '#version' do
      it { is_expected.to validate_presence_of(:version) }
      it { is_expected.to allow_value('1.2.3').for(:version) }
      it { is_expected.to allow_value('1.3.350').for(:version) }
      it { is_expected.to allow_value('1.3.350-20201230123456').for(:version) }
      it { is_expected.to allow_value('1.2.3-rc1').for(:version) }
      it { is_expected.to allow_value('1.2.3g').for(:version) }
      it { is_expected.to allow_value('1.2').for(:version) }
      it { is_expected.to allow_value('1.2.bananas').for(:version) }
      it { is_expected.to allow_value('v1.2.4-build').for(:version) }
      it { is_expected.to allow_value('d50d836eb3de6177ce6c7a5482f27f9c2c84b672').for(:version) }
      it { is_expected.to allow_value('this_is_a_string_only').for(:version) }
      it { is_expected.not_to allow_value('..1.2.3').for(:version) }
      it { is_expected.not_to allow_value('  1.2.3').for(:version) }
      it { is_expected.not_to allow_value("1.2.3  \r\t").for(:version) }
      it { is_expected.not_to allow_value("\r\t 1.2.3").for(:version) }
      it { is_expected.not_to allow_value('1.2.3-4/../../').for(:version) }
      it { is_expected.not_to allow_value('1.2.3-4%2e%2e%').for(:version) }
      it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
      it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
      it { is_expected.not_to allow_value('').for(:version) }
      it { is_expected.not_to allow_value(nil).for(:version) }
    end
  end
end
