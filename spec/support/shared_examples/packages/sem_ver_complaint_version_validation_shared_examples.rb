# frozen_string_literal: true

RSpec.shared_examples 'validating version to be SemVer compliant for' do |factory_name|
  context "for #{factory_name}" do
    subject { build_stubbed(factory_name) }

    it { is_expected.to allow_value('1.2.3').for(:version) }
    it { is_expected.to allow_value('1.2.3-beta').for(:version) }
    it { is_expected.to allow_value('1.2.3-alpha.3').for(:version) }
    it { is_expected.not_to allow_value('1').for(:version) }
    it { is_expected.not_to allow_value('1.2').for(:version) }
    it { is_expected.not_to allow_value('1./2.3').for(:version) }
    it { is_expected.not_to allow_value('../../../../../1.2.3').for(:version) }
    it { is_expected.not_to allow_value('%2e%2e%2f1.2.3').for(:version) }
  end
end
