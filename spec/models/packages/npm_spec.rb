# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Npm do
  using RSpec::Parameterized::TableSyntax

  describe '.scope_of' do
    subject { described_class.scope_of(package_name) }

    where(:package_name, :expected_result) do
      nil             | nil
      'test'          | nil
      '@test'         | nil
      'test/package'  | nil
      '@/package'     | nil
      '@test/package' | 'test'
      '@test/'        | nil
    end

    with_them do
      it { is_expected.to eq(expected_result) }
    end
  end
end
