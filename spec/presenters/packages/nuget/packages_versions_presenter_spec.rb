# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::PackagesVersionsPresenter do
  let_it_be(:packages) { create_list(:nuget_package, 5) }
  let_it_be(:presenter) { described_class.new(::Packages::Package.all) }

  describe '#versions' do
    subject { presenter.versions }

    it { is_expected.to match_array(packages.map(&:version).sort) }
  end
end
