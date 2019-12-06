# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectsBatchCounting do
  subject do
    Class.new do
      include ::API::ProjectsBatchCounting
    end
  end

  describe '.preload_and_batch_count!' do
    let(:projects) { double }
    let(:preloaded_projects) { double }

    it 'preloads the relation' do
      allow(subject).to receive(:execute_batch_counting).with(preloaded_projects)

      expect(subject).to receive(:preload_relation).with(projects).and_return(preloaded_projects)

      expect(subject.preload_and_batch_count!(projects)).to eq(preloaded_projects)
    end

    it 'executes batch counting' do
      allow(subject).to receive(:preload_relation).with(projects).and_return(preloaded_projects)

      expect(subject).to receive(:execute_batch_counting).with(preloaded_projects)

      subject.preload_and_batch_count!(projects)
    end
  end

  describe '.execute_batch_counting' do
    let(:projects) { create_list(:project, 2) }
    let(:count_service) { double }

    it 'counts forks' do
      allow(::Projects::BatchForksCountService).to receive(:new).with(projects).and_return(count_service)

      expect(count_service).to receive(:refresh_cache)

      subject.execute_batch_counting(projects)
    end

    it 'counts open issues' do
      allow(::Projects::BatchOpenIssuesCountService).to receive(:new).with(projects).and_return(count_service)

      expect(count_service).to receive(:refresh_cache)

      subject.execute_batch_counting(projects)
    end

    context 'custom fork counting' do
      subject do
        Class.new do
          include ::API::ProjectsBatchCounting
          def self.forks_counting_projects(projects)
            [projects.first]
          end
        end
      end

      it 'counts forks for other projects' do
        allow(::Projects::BatchForksCountService).to receive(:new).with([projects.first]).and_return(count_service)

        expect(count_service).to receive(:refresh_cache)

        subject.execute_batch_counting(projects)
      end
    end
  end
end
