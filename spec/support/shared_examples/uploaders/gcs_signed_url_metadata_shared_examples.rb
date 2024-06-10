# frozen_string_literal: true

RSpec.shared_examples 'augmenting GCS signed URL with metadata' do
  let(:project) { uploader.model.try(:project) }
  let(:root_namespace) { project&.root_namespace || uploader.model.try(:group).root_ancestor }
  let(:size) { uploader.model.try(:size) || uploader.model.file.size }
  let(:has_project?) { true }
  let(:connection) do
    {
      provider: 'Google',
      google_storage_access_key_id: 'test-access-id',
      google_storage_secret_access_key: 'secret'
    }
  end

  subject { uploader.model.file.url }

  context 'when the fog provider is not Google' do
    it { is_expected.not_to include('x-goog-custom-audit-gitlab-') }
  end

  context 'when the fog provider is Google' do
    before do
      stub_object_storage_uploader(
        config: Gitlab.config.packages.object_store.merge(connection: connection),
        uploader: described_class
      )
    end

    context 'when on GitLab.com', :saas do
      it do
        is_expected.to include(
          "x-goog-custom-audit-gitlab-namespace=#{root_namespace.id}",
          "x-goog-custom-audit-gitlab-size-bytes=#{size}"
        )
      end

      it { is_expected.to include("x-goog-custom-audit-gitlab-project=#{project.id}") if has_project? }

      context 'when an error occurs' do
        before do
          allow(uploader.model).to receive(:project).and_raise(StandardError)
          allow(::Gitlab::ErrorTracking).to receive(:track_exception)
        end

        it { expect { subject }.not_to raise_error }
        it { is_expected.not_to include('x-goog-custom-audit-gitlab-') }

        it 'tracks the error' do
          subject

          expect(::Gitlab::ErrorTracking).to have_received(:track_exception).with(
            an_instance_of(StandardError),
            model_class: uploader.model.class.name,
            model_id: uploader.model.id
          )
        end
      end
    end

    context 'when not on GitLab.com' do
      it { is_expected.not_to include('x-goog-custom-audit-gitlab-') }
    end
  end
end
