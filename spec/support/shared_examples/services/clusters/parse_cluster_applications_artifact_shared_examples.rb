# frozen_string_literal: true

RSpec.shared_examples 'parse cluster applications artifact' do |release_name|
  let(:application_class) { Clusters::Cluster::APPLICATIONS[release_name] }
  let(:cluster_application) { cluster.public_send("application_#{release_name}") }
  let(:file) { fixture_file_upload(Rails.root.join(fixture)) }
  let(:artifact) { create(:ci_job_artifact, :cluster_applications, job: job, file: file) }

  context 'release is missing' do
    let(:fixture) { "spec/fixtures/helm/helm_list_v2_#{release_name}_missing.json.gz" }

    context 'application does not exist' do
      it 'does not create or destroy an application' do
        expect do
          described_class.new(job, user).execute(artifact)
        end.not_to change(application_class, :count)
      end
    end

    context 'application exists' do
      before do
        create("clusters_applications_#{release_name}".to_sym, :installed, cluster: cluster)
      end

      it 'marks the application as uninstalled' do
        described_class.new(job, user).execute(artifact)

        cluster_application.reload
        expect(cluster_application).to be_uninstalled
      end
    end
  end

  context 'release is deployed' do
    let(:fixture) { "spec/fixtures/helm/helm_list_v2_#{release_name}_deployed.json.gz" }

    context 'application does not exist' do
      it 'creates an application and marks it as installed' do
        expect do
          described_class.new(job, user).execute(artifact)
        end.to change(application_class, :count)

        expect(cluster_application).to be_persisted
        expect(cluster_application).to be_externally_installed
      end
    end

    context 'application exists' do
      before do
        create("clusters_applications_#{release_name}".to_sym, :errored, cluster: cluster)
      end

      it 'marks the application as installed' do
        described_class.new(job, user).execute(artifact)

        expect(cluster_application).to be_externally_installed
      end
    end
  end

  context 'release is failed' do
    let(:fixture) { "spec/fixtures/helm/helm_list_v2_#{release_name}_failed.json.gz" }

    context 'application does not exist' do
      it 'creates an application and marks it as errored' do
        expect do
          described_class.new(job, user).execute(artifact)
        end.to change(application_class, :count)

        expect(cluster_application).to be_persisted
        expect(cluster_application).to be_errored
        expect(cluster_application.status_reason).to eq('Helm release failed to install')
      end
    end

    context 'application exists' do
      before do
        create("clusters_applications_#{release_name}".to_sym, :installed, cluster: cluster)
      end

      it 'marks the application as errored' do
        described_class.new(job, user).execute(artifact)

        expect(cluster_application).to be_errored
        expect(cluster_application.status_reason).to eq('Helm release failed to install')
      end
    end
  end
end
