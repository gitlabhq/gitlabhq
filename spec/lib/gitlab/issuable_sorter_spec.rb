# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::IssuableSorter do
  let(:namespace1) { build_stubbed(:namespace, id: 1) }
  let(:namespace2) { build_stubbed(:namespace, id: 2, path: "a") }
  let(:namespace3) { build_stubbed(:namespace, id: 3, path: "b") }

  let(:project1) do
    build_stubbed(:project, id: 1, namespace: namespace1, project_namespace: build_stubbed(:project_namespace))
  end

  let(:project2) do
    build_stubbed(
      :project, id: 2, path: "a", namespace: project1.namespace, project_namespace: build_stubbed(:project_namespace)
    )
  end

  let(:project3) do
    build_stubbed(
      :project, id: 3, path: "b", namespace: project1.namespace, project_namespace: build_stubbed(:project_namespace)
    )
  end

  let(:project4) do
    build_stubbed(
      :project, id: 4, path: "a", namespace: namespace2, project_namespace: build_stubbed(:project_namespace)
    )
  end

  let(:project5) do
    build_stubbed(
      :project, id: 5, path: "b", namespace: namespace2, project_namespace: build_stubbed(:project_namespace)
    )
  end

  let(:project6) do
    build_stubbed(
      :project, id: 6, path: "a", namespace: namespace3, project_namespace: build_stubbed(:project_namespace)
    )
  end

  let(:unsorted) { [sorted[2], sorted[3], sorted[0], sorted[1]] }

  let(:sorted) do
    [build_stubbed(:issue, iid: 1, project: project1),
     build_stubbed(:issue, iid: 2, project: project1),
     build_stubbed(:issue, iid: 10, project: project1),
     build_stubbed(:issue, iid: 20, project: project1)]
  end

  it 'sorts references by a given key' do
    expect(described_class.sort(project1, unsorted)).to eq(sorted)
  end

  context 'for Jira issues' do
    let(:sorted) do
      [ExternalIssue.new('JIRA-1', project1),
       ExternalIssue.new('JIRA-2', project1),
       ExternalIssue.new('JIRA-10', project1),
       ExternalIssue.new('JIRA-20', project1)]
    end

    it 'sorts references by a given key' do
      expect(described_class.sort(project1, unsorted)).to eq(sorted)
    end
  end

  context 'for references from multiple projects and namespaces' do
    let(:sorted) do
      [build_stubbed(:issue, iid: 1, project: project1),
       build_stubbed(:issue, iid: 2, project: project1),
       build_stubbed(:issue, iid: 10, project: project1),
       build_stubbed(:issue, iid: 1, project: project2),
       build_stubbed(:issue, iid: 1, project: project3),
       build_stubbed(:issue, iid: 1, project: project4),
       build_stubbed(:issue, iid: 1, project: project5),
       build_stubbed(:issue, iid: 1, project: project6)]
    end

    let(:unsorted) do
      [sorted[3], sorted[1], sorted[4], sorted[2],
       sorted[6], sorted[5], sorted[0], sorted[7]]
    end

    it 'sorts references by project and then by a given key' do
      expect(subject.sort(project1, unsorted)).to eq(sorted)
    end
  end
end
