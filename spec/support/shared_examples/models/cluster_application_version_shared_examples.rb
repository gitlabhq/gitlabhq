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

  describe '#make_installed' do
    subject { create(application_name, :installing) }

    it 'sets the correct version of the application' do
      subject.update!(version: '0.0.0')

      subject.make_installed!

      subject.reload

      expect(subject.version).to eq(subject.class.const_get(:VERSION, false))
    end

    context 'application is updating' do
      subject { create(application_name, :updating) }

      it 'updates the version of the application' do
        subject.update!(version: '0.0.0')

        subject.make_installed!

        subject.reload

        expect(subject.version).to eq(subject.class.const_get(:VERSION, false))
      end
    end
  end

  describe '#make_externally_installed' do
    subject { build(application_name) }

    it 'sets to a special version' do
      subject.make_externally_installed!

      expect(subject).to be_persisted
      expect(subject.version).to eq('EXTERNALLY_INSTALLED')
    end
  end
end
