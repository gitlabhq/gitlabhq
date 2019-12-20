# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Quality::HelmClient do
  let(:tiller_namespace) { 'review-apps-ee' }
  let(:namespace) { tiller_namespace }
  let(:release_name) { 'my-release' }
  let(:raw_helm_list_page1) do
    <<~OUTPUT
    {"Next":"review-6709-group-t40qbv",
      "Releases":[
        {"Name":"review-qa-60-reor-1mugd1", "Revision":1,"Updated":"Thu Oct  4 17:52:31 2018","Status":"FAILED", "Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-7846-fix-s-261vd6","Revision":1,"Updated":"Thu Oct  4 17:33:29 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-7867-snowp-lzo3iy","Revision":1,"Updated":"Thu Oct  4 17:22:14 2018","Status":"DEPLOYED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-rename-geo-o4a780","Revision":1,"Updated":"Thu Oct  4 17:14:57 2018","Status":"DEPLOYED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-5781-opera-0k93fx","Revision":1,"Updated":"Thu Oct  4 17:06:15 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-6709-group-2pzeec","Revision":1,"Updated":"Thu Oct  4 16:36:59 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-ce-to-ee-2-l554mn","Revision":1,"Updated":"Thu Oct  4 16:27:02 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-epics-e2e-m690eb","Revision":1,"Updated":"Thu Oct  4 16:08:26 2018","Status":"DEPLOYED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-7126-admin-06fae2","Revision":1,"Updated":"Thu Oct  4 15:56:35 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"},
        {"Name":"review-6983-promo-xyou11","Revision":1,"Updated":"Thu Oct  4 15:15:34 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"}
      ]}
    OUTPUT
  end
  let(:raw_helm_list_page2) do
    <<~OUTPUT
    {"Releases":[
      {"Name":"review-6709-group-t40qbv","Revision":1,"Updated":"Thu Oct  4 17:52:31 2018","Status":"FAILED","Chart":"gitlab-1.1.3","AppVersion":"master","Namespace":"#{namespace}"}
    ]}
    OUTPUT
  end

  subject { described_class.new(tiller_namespace: tiller_namespace, namespace: namespace) }

  describe '#releases' do
    it 'raises an error if the Helm command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}" --tiller-namespace "#{tiller_namespace}" --output json)])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.releases.to_a }.to raise_error(described_class::CommandFailedError)
    end

    it 'calls helm list with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}" --tiller-namespace "#{tiller_namespace}" --output json)])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      subject.releases.to_a
    end

    it 'calls helm list with extra arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}" --tiller-namespace "#{tiller_namespace}" --output json --deployed)])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      subject.releases(args: ['--deployed']).to_a
    end

    it 'returns a list of Release objects' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm list --namespace "#{namespace}" --tiller-namespace "#{tiller_namespace}" --output json --deployed)])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_page2, '', double(success?: true)))

      releases = subject.releases(args: ['--deployed']).to_a

      expect(releases.size).to eq(1)
      expect(releases[0]).to have_attributes(
        name: 'review-6709-group-t40qbv',
        revision: 1,
        last_update: Time.parse('Thu Oct 4 17:52:31 2018'),
        status: 'FAILED',
        chart: 'gitlab-1.1.3',
        app_version: 'master',
        namespace: namespace
      )
    end

    it 'automatically paginates releases' do
      expect(Gitlab::Popen).to receive(:popen_with_detail).ordered
        .with([%(helm list --namespace "#{namespace}" --tiller-namespace "#{tiller_namespace}" --output json)])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_page1, '', double(success?: true)))
      expect(Gitlab::Popen).to receive(:popen_with_detail).ordered
        .with([%(helm list --namespace "#{namespace}" --tiller-namespace "#{tiller_namespace}" --output json --offset review-6709-group-t40qbv)])
        .and_return(Gitlab::Popen::Result.new([], raw_helm_list_page2, '', double(success?: true)))

      releases = subject.releases.to_a

      expect(releases.size).to eq(11)
      expect(releases.last.name).to eq('review-6709-group-t40qbv')
    end
  end

  describe '#delete' do
    it 'raises an error if the Helm command fails' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm delete --tiller-namespace "#{tiller_namespace}" --purge #{release_name})])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

      expect { subject.delete(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
    end

    it 'calls helm delete with default arguments' do
      expect(Gitlab::Popen).to receive(:popen_with_detail)
        .with([%(helm delete --tiller-namespace "#{tiller_namespace}" --purge #{release_name})])
        .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

      expect(subject.delete(release_name: release_name)).to eq('')
    end

    context 'with multiple release names' do
      let(:release_name) { %w[my-release my-release-2] }

      it 'raises an error if the Helm command fails' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
                                   .with([%(helm delete --tiller-namespace "#{tiller_namespace}" --purge #{release_name.join(' ')})])
                                   .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: false)))

        expect { subject.delete(release_name: release_name) }.to raise_error(described_class::CommandFailedError)
      end

      it 'calls helm delete with multiple release names' do
        expect(Gitlab::Popen).to receive(:popen_with_detail)
                                   .with([%(helm delete --tiller-namespace "#{tiller_namespace}" --purge #{release_name.join(' ')})])
                                   .and_return(Gitlab::Popen::Result.new([], '', '', double(success?: true)))

        expect(subject.delete(release_name: release_name)).to eq('')
      end
    end
  end
end
