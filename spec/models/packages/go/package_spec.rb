# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::Package, type: :model, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:golang_package) { build_stubbed(:golang_package) }

  describe 'validations' do
    where(:version, :valid) do
      'v1.2.3'                | true
      'v1.2.3-beta'           | true
      'v1.2.3-alpha.3'        | true
      'v1'                    | false
      'v1.2'                  | false
      'v1./2.3'               | false
      'v../../../../../1.2.3' | false
      'v%2e%2e%2f1.2.3'       | false
    end

    with_them do
      if params[:valid]
        it { is_expected.to allow_value(version).for(:version) }
      else
        it { is_expected.not_to allow_value(version).for(:version) }
      end
    end
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :golang_package
  end
end
