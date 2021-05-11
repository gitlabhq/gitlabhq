# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Debian Distribution Architecture' do |factory, container, can_freeze|
  let_it_be_with_refind(:architecture) { create(factory, name: 'name1') }
  let_it_be(:architecture_same_distribution, freeze: can_freeze) { create(factory, distribution: architecture.distribution, name: 'name2') }
  let_it_be(:architecture_same_name, freeze: can_freeze) { create(factory, name: architecture.name) }

  subject { architecture }

  describe 'relationships' do
    it { is_expected.to belong_to(:distribution).class_name("Packages::Debian::#{container.capitalize}Distribution").inverse_of(:architectures) }
    it { is_expected.to have_many(:files).class_name("Packages::Debian::#{container.capitalize}ComponentFile").inverse_of(:architecture) }
  end

  describe 'validations' do
    describe "#distribution" do
      it { is_expected.to validate_presence_of(:distribution) }
    end

    describe '#name' do
      it { is_expected.to validate_presence_of(:name) }

      it { is_expected.to allow_value('amd64').for(:name) }
      it { is_expected.to allow_value('kfreebsd-i386').for(:name) }
      it { is_expected.not_to allow_value('-a').for(:name) }
      it { is_expected.not_to allow_value('AMD64').for(:name) }
    end
  end

  describe 'scopes' do
    describe '.ordered_by_name' do
      subject { described_class.with_distribution(architecture.distribution).ordered_by_name }

      it { expect(subject).to match_array([architecture, architecture_same_distribution]) }
    end

    describe '.with_distribution' do
      subject { described_class.with_distribution(architecture.distribution) }

      it { expect(subject).to match_array([architecture, architecture_same_distribution]) }
    end

    describe '.with_name' do
      subject { described_class.with_name(architecture.name) }

      it { expect(subject).to match_array([architecture, architecture_same_name]) }
    end
  end
end
