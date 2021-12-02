# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::PackagesConanUserChannel do
  include ApiValidatorsHelpers

  describe '#validate_param!' do
    subject do
      described_class.new(['test'], {}, false, scope.new)
    end

    shared_examples 'accepting valid values for conan user channels' do
      let(:fifty_one_characters) { 'f_a' * 17}

      it { expect_no_validation_error('test' => 'foobar') }
      it { expect_no_validation_error('test' => 'foo_bar') }
      it { expect_no_validation_error('test' => 'foo+bar') }
      it { expect_no_validation_error('test' => '_foo+bar-baz+1.0') }
      it { expect_no_validation_error('test' => '1.0.0') }
      it { expect_validation_error('test' => '-foo_bar') }
      it { expect_validation_error('test' => '+foo_bar') }
      it { expect_validation_error('test' => '.foo_bar') }
      it { expect_validation_error('test' => 'foo@bar') }
      it { expect_validation_error('test' => 'foo/bar') }
      it { expect_validation_error('test' => '!!()()') }
      it { expect_validation_error('test' => fifty_one_characters) }
    end

    it_behaves_like 'accepting valid values for conan user channels'
    it { expect_no_validation_error('test' => '_') }

    context 'with packages_conan_allow_empty_username_channel disabled' do
      before do
        stub_feature_flags(packages_conan_allow_empty_username_channel: false)
      end

      it_behaves_like 'accepting valid values for conan user channels'
      it { expect_validation_error('test' => '_') }
    end
  end
end
