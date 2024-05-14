# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/helm3_client'

RSpec.describe Tooling::Helm3Client do
  let(:release_name) { 'my-release' }
  let(:raw_helm_list_page1) do
    <<~OUTPUT
    [
      {"name":"review-qa-60-reor-1mugd1","namespace":"review-qa-60-reor-1mugd1","revision":1,"updated":"2020-04-03 17:27:10.245952 +0800 +08","status":"failed","chart":"gitlab-1.1.3","app_version":"12.9.2"},
      {"name":"review-7846-fix-s-261vd6","namespace":"review-7846-fix-s-261vd6","revision":2,"updated":"2020-04-02 17:27:12.245952 +0800 +08","status":"deployed","chart":"gitlab-1.1.3","app_version":"12.9.2"},
      {"name":"review-7867-snowp-lzo3iy","namespace":"review-7867-snowp-lzo3iy","revision":1,"updated":"2020-04-02 15:27:12.245952 +0800 +08","status":"deployed","chart":"gitlab-1.1.3","app_version":"12.9.1"},
      {"name":"review-6709-group-2pzeec","namespace":"review-6709-group-2pzeec","revision":2,"updated":"2020-04-01 21:27:12.245952 +0800 +08","status":"failed","chart":"gitlab-1.1.3","app_version":"12.9.1"}
    ]
    OUTPUT
  end

  let(:raw_helm_list_page2) do
    <<~OUTPUT
    [
      {"name":"review-6709-group-t40qbv","namespace":"review-6709-group-t40qbv","revision":2,"updated":"2020-04-01 11:27:12.245952 +0800 +08","status":"deployed","chart":"gitlab-1.1.3","app_version":"12.9.1"}
    ]
    OUTPUT
  end

  let(:raw_helm_list_empty) do
    <<~OUTPUT
    []
    OUTPUT
  end

  subject { described_class.new }

  describe '#releases' do
    it 'raises an error if the Helm command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm", "list", "--max", "256", "--offset", "0", "--output", "json"])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.releases.to_a }.to raise_error(described_class::CommandFailedError)
    end

    it 'calls helm list with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm", "list", "--max", "256", "--offset", "0", "--output", "json"])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      subject.releases.to_a
    end

    it 'calls helm list with extra arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm", "list", "--max", "256", "--offset", "0", "--output", "json", "--deployed"])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      subject.releases(args: ['--deployed']).to_a
    end

    it 'returns a list of Release objects' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm", "list", "--max", "256", "--offset", "0", "--output", "json", "--deployed"])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_page2, '', double(success?: true)))
      expect(Gitlab::Popen).to receive(:popen_with_detail).ordered
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_empty, '', double(success?: true)))

      releases = subject.releases(args: ['--deployed']).to_a

      expect(releases.size).to eq(1)
      expect(releases[0]).to have_attributes(
        name: 'review-6709-group-t40qbv',
        revision: 2,
        last_update: Time.parse('2020-04-01 11:27:12.245952 +0800 +08'),
        status: 'deployed',
        chart: 'gitlab-1.1.3',
        app_version: '12.9.1',
        namespace: 'review-6709-group-t40qbv'
      )
    end

    it 'automatically paginates releases' do
      expect(Gitlab::Popen).to receive(:popen_with_detail).ordered
        .with(["helm", "list", "--max", "256", "--offset", "0", "--output", "json"])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_page1, '', double(success?: true)))
      expect(Gitlab::Popen).to receive(:popen_with_detail).ordered
        .with(["helm", "list", "--max", "256", "--offset", "256", "--output", "json"])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_page2, '', double(success?: true)))
      expect(Gitlab::Popen).to receive(:popen_with_detail).ordered
        .with(["helm", "list", "--max", "256", "--offset", "512", "--output", "json"])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_empty, '', double(success?: true)))
      releases = subject.releases.to_a

      expect(releases.size).to eq(5)
      expect(releases.last.name).to eq('review-6709-group-t40qbv')
    end
  end

  describe '#delete' do
    it 'raises an error if the Helm command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm", "uninstall", "--namespace", release_name, release_name])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.delete(release_name: release_name, namespace: release_name) }
        .to raise_error(described_class::CommandFailedError)
    end

    it 'calls helm uninstall with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm", "uninstall", "--namespace", release_name, release_name])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      subject.delete(release_name: release_name, namespace: release_name)
    end

    context 'with multiple release names' do
      let(:release_name) { %w[my-release my-release-2] }

      it 'raises an error if the Helm command fails' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
          .with(["helm", "uninstall", "--namespace", release_name[0], release_name[0]])
          .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

        expect { subject.delete(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
      end

      it 'calls helm uninstall with multiple release names and a namespace' do
        release_name.each do |release|
          expect(Gitlab::Popen).to receive(:popen_with_detail)
            .with(["helm", "uninstall", "--namespace", "namespace", release])
            .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))
        end

        subject.delete(release_name: release_name, namespace: 'namespace')
      end

      it 'calls helm uninstall with multiple release names and no namespace' do
        release_name.each do |release|
          expect(Gitlab::Popen).to receive(:popen_with_detail)
            .with(["helm", "uninstall", "--namespace", release, release])
            .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))
        end

        subject.delete(release_name: release_name)
      end
    end
  end
end
