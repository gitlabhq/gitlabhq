# frozen_string_literal: true

RSpec.describe Quality::HelmClient do
  let(:namespace) { 'review-apps-ee' }
  let(:release_name) { 'my-release' }
  let(:raw_helm_list_result) do
    <<~OUTPUT
    NAME                    	REVISION	UPDATED                 	STATUS	CHART       	NAMESPACE
    review-improve-re-2dsd9d	1       	Tue Jul 31 15:53:17 2018	FAILED	gitlab-0.3.4	#{namespace}
    review-11-1-stabl-3r2fso	1       	Mon Jul 30 22:44:14 2018	FAILED	gitlab-0.3.3	#{namespace}
    review-49375-css-fk664j 	1       	Thu Jul 19 11:01:30 2018	FAILED	gitlab-0.2.4	#{namespace}
    OUTPUT
  end

  subject { described_class.new(namespace: namespace) }

  describe '#releases' do
    it 'calls helm list with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}")])
        .and_return(Gitlab::Popen::Result.new([], ''))

      subject.releases
    end

    it 'calls helm list with given arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}" --deployed)])
        .and_return(Gitlab::Popen::Result.new([], ''))

      subject.releases(args: ['--deployed'])
    end

    it 'returns a list of Release objects' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}" --deployed)])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_result))

      releases = subject.releases(args: ['--deployed'])

      expect(releases.size).to eq(3)
      expect(releases[0].name).to eq('review-improve-re-2dsd9d')
      expect(releases[0].revision).to eq(1)
      expect(releases[0].last_update).to eq(Time.parse('Tue Jul 31 15:53:17 2018'))
      expect(releases[0].status).to eq('FAILED')
      expect(releases[0].chart).to eq('gitlab-0.3.4')
      expect(releases[0].namespace).to eq(namespace)
    end
  end

  describe '#delete' do
    it 'calls helm delete with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with(["helm delete --purge #{release_name}"])
        .and_return(Gitlab::Popen::Result.new([], '', '', 0))

      expect(subject.delete(release_name: release_name).status).to eq(0)
    end
  end
end
