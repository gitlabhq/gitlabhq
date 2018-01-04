shared_examples 'cluster application specs' do
  let(:factory_name) { described_class.to_s.downcase.gsub("::", "_") }

  describe '#name' do
    it 'is .application_name' do
      expect(subject.name).to eq(described_class.application_name)
    end

    it 'is recorded in Clusters::Cluster::APPLICATIONS' do
      expect(Clusters::Cluster::APPLICATIONS[subject.name]).to eq(described_class)
    end
  end

  describe '#status' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { described_class.new(cluster: cluster) }

    it 'defaults to :not_installable' do
      expect(subject.status_name).to be(:not_installable)
    end

    context 'when application helm is scheduled' do
      before do
        create(factory_name, :scheduled, cluster: cluster)
      end

      it 'defaults to :not_installable' do
        expect(subject.status_name).to be(:not_installable)
      end
    end

    context 'when application helm is installed' do
      before do
        create(:clusters_applications_helm, :installed, cluster: cluster)
      end

      it 'defaults to :installable' do
        expect(subject.status_name).to be(:installable)
      end
    end
  end

  describe '#install_command' do
    it 'has all the needed information' do
      expect(subject.install_command).to have_attributes(name: subject.name, install_helm: false)
    end
  end

  describe 'status state machine' do
    describe '#make_installing' do
      subject { create(factory_name, :scheduled) }

      it 'is installing' do
        subject.make_installing!

        expect(subject).to be_installing
      end
    end

    describe '#make_installed' do
      subject { create(factory_name, :installing) }

      it 'is installed' do
        subject.make_installed

        expect(subject).to be_installed
      end
    end

    describe '#make_errored' do
      subject { create(factory_name, :installing) }
      let(:reason) { 'some errors' }

      it 'is errored' do
        subject.make_errored(reason)

        expect(subject).to be_errored
        expect(subject.status_reason).to eq(reason)
      end
    end

    describe '#make_scheduled' do
      subject { create(factory_name, :installable) }

      it 'is scheduled' do
        subject.make_scheduled

        expect(subject).to be_scheduled
      end

      describe 'when was errored' do
        subject { create(factory_name, :errored) }

        it 'clears #status_reason' do
          expect(subject.status_reason).not_to be_nil

          subject.make_scheduled!

          expect(subject.status_reason).to be_nil
        end
      end
    end
  end
end
