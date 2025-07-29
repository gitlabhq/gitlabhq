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

  context 'when allow_initial_path_separator is set' do
    let(:params) { { allow_initial_path_separator: true } }

    context 'when file path starts with encoded forward slash' do
      it 'allows paths with encoded separators that decode to absolute paths' do
        expect_no_validation_error('test' => '%2Ffoo%2F')
        expect_no_validation_error('test' => '%2Ffoo%2Fconfig.txt')
        expect_no_validation_error('test' => '%2Ffoo%2Fbar%2Ffile.txt')
      end

      it 'allows mixed encoded/decoded paths' do
        expect_no_validation_error('test' => '%2Ffoo/bar')
      end
    end

    context 'when file path is a non-encoded absolute path' do
      it 'raise a validation error' do
        expect_validation_error('test' => '/foo/bar')
      end
    end

    context 'when file path is a traversal attempt' do
      it 'blocks double-encoded traversal attempts' do
        expect_validation_error('test' => '%252E%252E%252F')
        expect_validation_error('test' => '%252E%252E%252Fetc%252Fpasswd')
        expect_validation_error('test' => '%2Ffoo%252E%252E%252Fbar')
      end

      it 'blocks mixed encoding patterns' do
        expect_validation_error('test' => '%2F..%2Fetc')
        expect_validation_error('test' => '%2Ffoo%2F..%2Fetc%2Fpasswd')
        expect_validation_error('test' => '%2F..%2F..%2Fetc%2Fpasswd')
        expect_validation_error('test' => '%2Fdir%2F..%2F..%2Fpasswd')
      end

      it 'blocks encoded traversal with legitimate directory names' do
        expect_validation_error('test' => '%2Ffoo%2F..%2Fbar')
        expect_validation_error('test' => '%2FSAP%2F..%2F..%2Fetc%2Fpasswd')
      end
    end
  end
end
