# frozen_string_literal: true

RSpec.shared_examples 'cluster application version specs' do |application_name|
  describe 'update_available?' do
    let_it_be(:cluster) { create(:cluster, :provided_by_gcp) }

    let(:version) { '0.0.0' }

    subject { build(application_name, :installed, version: version, cluster: cluster).update_available? }

    context 'version is not the same as VERSION' do
      it { is_expected.to be_truthy }
    end

    context 'version is the same as VERSION' do
      let(:application) { build(application_name, cluster: cluster) }
      let(:version) { application.class.const_get(:VERSION, false) }

      it { is_expected.to be_falsey }
    end
  end
end
