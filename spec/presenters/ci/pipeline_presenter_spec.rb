# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelinePresenter do
  include Gitlab::Routing

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  subject(:presenter) do
    described_class.new(pipeline)
  end

  before do
    project.add_developer(user)
    allow(presenter).to receive(:current_user) { user }
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a pipeline and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes pipeline' do
      expect(presenter.pipeline).to eq(pipeline)
    end

    it 'forwards missing methods to pipeline' do
      expect(presenter.ref).to eq(pipeline.ref)
    end
  end

  describe '#status_title' do
    context 'when pipeline is auto-canceled' do
      before do
        expect(pipeline).to receive(:auto_canceled?).and_return(true)
        expect(pipeline).to receive(:auto_canceled_by_id).and_return(1)
      end

      it 'shows that the pipeline is auto-canceled' do
        status_title = presenter.status_title

        expect(status_title).to include('auto-canceled')
        expect(status_title).to include('Pipeline #1')
      end
    end

    context 'when pipeline is not auto-canceled' do
      before do
        expect(pipeline).to receive(:auto_canceled?).and_return(false)
      end

      it 'does not have a status title' do
        expect(presenter.status_title).to be_nil
      end
    end
  end

  describe '#failure_reason' do
    context 'when pipeline has a failure reason' do
      ::Ci::PipelineEnums.failure_reasons.keys.each do |failure_reason|
        context "when failure reason is #{failure_reason}" do
          before do
            pipeline.failure_reason = failure_reason
          end

          it 'represents a failure reason sentence' do
            expect(presenter.failure_reason).to be_an_instance_of(String)
            expect(presenter.failure_reason).not_to eq(failure_reason.to_s)
          end
        end
      end
    end

    context 'when pipeline does not have failure reason' do
      it 'returns nil' do
        expect(presenter.failure_reason).to be_nil
      end
    end
  end

  describe '#name' do
    subject { presenter.name }

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.last }

      it { is_expected.to eq('Detached merge request pipeline') }
    end

    context 'when pipeline is merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.last }

      it { is_expected.to eq('Merged result pipeline') }
    end

    context 'when pipeline is merge train pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      before do
        allow(pipeline).to receive(:merge_request_event_type) { :merge_train }
      end

      it { is_expected.to eq('Merge train pipeline') }
    end

    context 'when pipeline is branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it { is_expected.to eq('Pipeline') }
    end
  end

  describe '#ref_text' do
    subject { presenter.ref_text }

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.last }

      it 'returns a correct ref text' do
        is_expected.to eq("for <a class=\"mr-iid\" href=\"#{project_merge_request_path(merge_request.project, merge_request)}\">#{merge_request.to_reference}</a> " \
                          "with <a class=\"ref-name\" href=\"#{project_commits_path(merge_request.source_project, merge_request.source_branch)}\">#{merge_request.source_branch}</a>")
      end
    end

    context 'when pipeline is merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.last }

      it 'returns a correct ref text' do
        is_expected.to eq("for <a class=\"mr-iid\" href=\"#{project_merge_request_path(merge_request.project, merge_request)}\">#{merge_request.to_reference}</a> " \
                          "with <a class=\"ref-name\" href=\"#{project_commits_path(merge_request.source_project, merge_request.source_branch)}\">#{merge_request.source_branch}</a> " \
                          "into <a class=\"ref-name\" href=\"#{project_commits_path(merge_request.target_project, merge_request.target_branch)}\">#{merge_request.target_branch}</a>")
      end
    end

    context 'when pipeline is branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      context 'when ref exists in the repository' do
        before do
          allow(pipeline).to receive(:ref_exists?) { true }
        end

        it 'returns a correct ref text' do
          is_expected.to eq("for <a class=\"ref-name\" href=\"#{project_commits_path(pipeline.project, pipeline.ref)}\">#{pipeline.ref}</a>")
        end

        context 'when ref contains malicious script' do
          let(:pipeline) { create(:ci_pipeline, ref: "<script>alter('1')</script>", project: project) }

          it 'does not include the malicious script' do
            is_expected.not_to include("<script>alter('1')</script>")
          end
        end
      end

      context 'when ref exists in the repository' do
        before do
          allow(pipeline).to receive(:ref_exists?) { false }
        end

        it 'returns a correct ref text' do
          is_expected.to eq("for <span class=\"ref-name\">#{pipeline.ref}</span>")
        end

        context 'when ref contains malicious script' do
          let(:pipeline) { create(:ci_pipeline, ref: "<script>alter('1')</script>", project: project) }

          it 'does not include the malicious script' do
            is_expected.not_to include("<script>alter('1')</script>")
          end
        end
      end
    end
  end

  describe '#all_related_merge_request_text' do
    subject { presenter.all_related_merge_request_text }

    context 'with zero related merge requests (branch pipeline)' do
      it { is_expected.to eq('No related merge requests found.') }
    end

    context 'with one related merge request' do
      let!(:mr_1) { create(:merge_request, project: project, source_project: project) }

      it {
        is_expected.to eq("1 related merge request: " \
          "<a class=\"mr-iid\" href=\"#{merge_request_path(mr_1)}\">#{mr_1.to_reference} #{mr_1.title}</a>")
      }
    end

    context 'with two related merge requests' do
      let!(:mr_1) { create(:merge_request, project: project, source_project: project, target_branch: 'staging') }
      let!(:mr_2) { create(:merge_request, project: project, source_project: project, target_branch: 'feature') }

      it {
        is_expected.to eq("2 related merge requests: " \
          "<a class=\"mr-iid\" href=\"#{merge_request_path(mr_2)}\">#{mr_2.to_reference} #{mr_2.title}</a>, " \
          "<a class=\"mr-iid\" href=\"#{merge_request_path(mr_1)}\">#{mr_1.to_reference} #{mr_1.title}</a>")
      }
    end
  end

  describe '#all_related_merge_requests' do
    it 'memoizes the returned relation' do
      query_count = ActiveRecord::QueryRecorder.new do
        2.times { presenter.send(:all_related_merge_requests).count }
      end.count

      expect(query_count).to eq(1)
    end
  end

  describe '#link_to_merge_request' do
    subject { presenter.link_to_merge_request }

    let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
    let(:pipeline) { merge_request.all_pipelines.last }

    it 'returns a correct link' do
      is_expected
        .to include(project_merge_request_path(merge_request.project, merge_request))
    end

    context 'when pipeline is branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end

  describe '#link_to_merge_request_source_branch' do
    subject { presenter.link_to_merge_request_source_branch }

    let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
    let(:pipeline) { merge_request.all_pipelines.last }

    it 'returns a correct link' do
      is_expected
        .to include(project_commits_path(merge_request.source_project,
                                             merge_request.source_branch))
    end

    context 'when pipeline is branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end

  describe '#link_to_merge_request_target_branch' do
    subject { presenter.link_to_merge_request_target_branch }

    let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }
    let(:pipeline) { merge_request.all_pipelines.last }

    it 'returns a correct link' do
      is_expected
        .to include(project_commits_path(merge_request.target_project, merge_request.target_branch))
    end

    context 'when pipeline is branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project) }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end
end
