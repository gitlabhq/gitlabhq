# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::FilePath do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], params, false, scope.new)
  end

  context 'when allowlist is not set' do
    shared_examples 'file validation' do
      context 'valid file path' do
        it 'does not raise a validation error' do
          expect_no_validation_error('test' => './foo')
          expect_no_validation_error('test' => './bar.rb')
          expect_no_validation_error('test' => 'foo%2Fbar%2Fnew%2Ffile.rb')
          expect_no_validation_error('test' => 'foo%2Fbar%2Fnew')
          expect_no_validation_error('test' => 'foo/bar')
        end
      end

      context 'invalid file path' do
        it 'raise a validation error' do
          expect_validation_error('test' => '../foo')
          expect_validation_error('test' => '../')
          expect_validation_error('test' => 'foo/../../bar')
          expect_validation_error('test' => 'foo/../')
          expect_validation_error('test' => 'foo/..')
          expect_validation_error('test' => '../')
          expect_validation_error('test' => '..\\')
          expect_validation_error('test' => '..\/')
          expect_validation_error('test' => '%2e%2e%2f')
          expect_validation_error('test' => '/etc/passwd')
          expect_validation_error('test' => 'test%0a/etc/passwd')
          expect_validation_error('test' => '%2Ffoo%2Fbar%2Fnew%2Ffile.rb')
          expect_validation_error('test' => '%252Ffoo%252Fbar%252Fnew%252Ffile.rb')
          expect_validation_error('test' => 'foo%252Fbar%252Fnew%252Ffile.rb')
          expect_validation_error('test' => 'foo%25252Fbar%25252Fnew%25252Ffile.rb')
        end
      end
    end

    it_behaves_like 'file validation' do
      let(:params) { {} }
    end

    it_behaves_like 'file validation' do
      let(:params) { true }
    end
  end

  context 'when allowlist is set' do
    let(:params) { { allowlist: ['/home/bar'] } }

    context 'when file path is included in the allowlist' do
      it 'does not raise a validation error' do
        expect_no_validation_error('test' => '/home/bar')
      end
    end

    context 'when file path is not included in the allowlist' do
      it 'raises a validation error' do
        expect_validation_error('test' => '/foo/xyz')
      end
    end
  end
end
