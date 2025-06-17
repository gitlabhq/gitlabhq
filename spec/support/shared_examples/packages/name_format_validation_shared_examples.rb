# frozen_string_literal: true

RSpec.shared_examples 'validate package name format' do |factory_name|
  context "for #{factory_name}" do
    subject { build_stubbed(factory_name) }

    it { is_expected.to allow_value('MyPackage').for(:name) }
    it { is_expected.to allow_value('My.Package.Mvc').for(:name) }
    it { is_expected.to allow_value('@My/Package.Name').for(:name) }
    it { is_expected.to allow_value('1.0.0').for(:name) }
    it { is_expected.to allow_value('my.package/name.1.0.0').for(:name) }
    it { is_expected.to allow_value('my-test-package@0.6.4').for(:name) }
    it { is_expected.to allow_value('my.app-11.07.2018').for(:name) }
    it { is_expected.to allow_value('my/domain/com/my-app').for(:name) }

    it { is_expected.not_to allow_value('@@scope/../../package').for(:name) }
    it { is_expected.not_to allow_value('my(dom$$$ain)com.my-app').for(:name) }
  end
end
