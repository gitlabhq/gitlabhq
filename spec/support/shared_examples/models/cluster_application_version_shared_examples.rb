# frozen_string_literal: true

shared_examples 'cluster application version specs' do |application_name|
  describe 'update_available?' do
    let(:version) { '0.0.0' }

    subject { create(application_name, :installed, version: version).update_available? }

    context 'version is not the same as VERSION' do
      it { is_expected.to be_truthy }
    end

    context 'version is the same as VERSION' do
      let(:application) { build(application_name) }
      let(:version) { application.class.const_get(:VERSION) }

      it { is_expected.to be_falsey }
    end
  end
end
