# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Debian Distributions Finder' do |factory, can_freeze|
  let_it_be(:distribution_with_suite, freeze: can_freeze) { create(factory, :with_suite) }
  let_it_be(:container) { distribution_with_suite.container }
  let_it_be(:distribution_with_same_container, freeze: can_freeze) { create(factory, container: container) }
  let_it_be(:distribution_with_same_codename, freeze: can_freeze) { create(factory, codename: distribution_with_suite.codename) }
  let_it_be(:distribution_with_same_suite, freeze: can_freeze) { create(factory, suite: distribution_with_suite.suite) }
  let_it_be(:distribution_with_codename_and_suite_flipped, freeze: can_freeze) { create(factory, codename: distribution_with_suite.suite, suite: distribution_with_suite.codename) }

  let(:params) { {} }
  let(:service) { described_class.new(container, params) }

  subject { service.execute.to_a }

  context 'by codename' do
    context 'with existing codename' do
      let(:params) { { codename: distribution_with_suite.codename } }

      it 'finds distributions by codename' do
        is_expected.to contain_exactly(distribution_with_suite)
      end
    end

    context 'with non-existing codename' do
      let(:params) { { codename: 'does_not_exists' } }

      it 'finds nothing' do
        is_expected.to be_empty
      end
    end
  end

  context 'by suite' do
    context 'with existing suite' do
      let(:params) { { suite: distribution_with_suite.suite } }

      it 'finds distribution by suite' do
        is_expected.to contain_exactly(distribution_with_suite)
      end
    end

    context 'with non-existing suite' do
      let(:params) { { suite: 'does_not_exists' } }

      it 'finds nothing' do
        is_expected.to be_empty
      end
    end
  end

  context 'by codename_or_suite' do
    context 'with existing codename' do
      let(:params) { { codename_or_suite: distribution_with_suite.codename } }

      it 'finds distribution by codename' do
        is_expected.to contain_exactly(distribution_with_suite)
      end
    end

    context 'with existing suite' do
      let(:params) { { codename_or_suite: distribution_with_suite.suite } }

      it 'finds distribution by suite' do
        is_expected.to contain_exactly(distribution_with_suite)
      end
    end

    context 'with non-existing suite' do
      let(:params) { { codename_or_suite: 'does_not_exists' } }

      it 'finds nothing' do
        is_expected.to be_empty
      end
    end
  end
end
