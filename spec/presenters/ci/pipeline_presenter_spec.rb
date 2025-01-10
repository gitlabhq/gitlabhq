# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinePresenter do
  include Gitlab::Routing

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :test_repo, developers: user) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }

  let(:current_user) { user }

  subject(:presenter) do
    described_class.new(pipeline)
  end

  before do
    allow(presenter).to receive(:current_user) { current_user }
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
      Enums::Ci::Pipeline.failure_reasons.keys.each do |failure_reason|
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

  describe '#event_type_name' do
    before do
      allow(pipeline).to receive(:merge_request_event_type) { event_type }
    end

    subject { presenter.event_type_name }

    context 'for a detached merge request pipeline' do
      let(:event_type) { :detached }

      it { is_expected.to eq('Merge request pipeline') }
    end

    context 'for a merged results pipeline' do
      let(:event_type) { :merged_result }

      it { is_expected.to eq('Merged results pipeline') }
    end

    context 'for a merge train pipeline' do
      let(:event_type) { :merge_train }

      it { is_expected.to eq('Merge train pipeline') }
    end

    context 'when pipeline is branch pipeline' do
      let(:event_type) { nil }

      it { is_expected.to eq('Pipeline') }
    end
  end

  describe '#coverage' do
    subject { presenter.coverage }

    context 'when pipeline has coverage' do
      before do
        allow(pipeline).to receive(:coverage).and_return(35.0)
      end

      it 'formats coverage into 2 decimal points' do
        expect(subject).to eq('35.00')
      end
    end

    context 'when pipeline does not have coverage' do
      before do
        allow(pipeline).to receive(:coverage).and_return(nil)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#ref_text' do
    subject { presenter.ref_text }

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.last }

      it 'returns a correct ref text' do
        is_expected.to eq("Related merge request <a class=\"mr-iid ref-container\" href=\"#{project_merge_request_path(merge_request.project, merge_request)}\">#{merge_request.to_reference}</a> " \
                          "to merge <a class=\"ref-container gl-link\" href=\"#{project_commits_path(merge_request.source_project, merge_request.source_branch)}\">#{merge_request.source_branch}</a>")
      end
    end

    context 'when pipeline is merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }
      let(:pipeline) { merge_request.all_pipelines.last }

      it 'returns a correct ref text' do
        is_expected.to eq("Related merge request <a class=\"mr-iid ref-container\" href=\"#{project_merge_request_path(merge_request.project, merge_request)}\">#{merge_request.to_reference}</a> " \
                          "to merge <a class=\"ref-container gl-link\" href=\"#{project_commits_path(merge_request.source_project, merge_request.source_branch)}\">#{merge_request.source_branch}</a> " \
                          "into <a class=\"ref-container gl-link\" href=\"#{project_commits_path(merge_request.target_project, merge_request.target_branch)}\">#{merge_request.target_branch}</a>")
      end
    end

    context 'with multiple related merge requests' do
      let(:mr_1) { create(:merge_request) }
      let(:mr_2) { create(:merge_request) }

      before do
        allow(pipeline).to receive(:all_merge_requests).and_return(MergeRequest.where(id: [mr_1.id, mr_2.id]))
      end

      it 'displays the correct amount of links for the related merge requests' do
        is_expected.to eq("2 related merge requests: <a class=\"mr-iid\" href=\"#{project_merge_request_path(mr_2.project, mr_2)}\">#{mr_2.to_reference} #{mr_2.title}</a>, " \
                          "<a class=\"mr-iid\" href=\"#{project_merge_request_path(mr_1.project, mr_1)}\">#{mr_1.to_reference} #{mr_1.title}</a>")
      end
    end

    context 'with just one merge request' do
      let(:mr_1) { create(:merge_request) }

      before do
        allow(pipeline).to receive(:all_merge_requests).and_return(MergeRequest.where(id: mr_1.id))
      end

      it 'displays the link for the related merge request' do
        is_expected.to eq("1 related merge request: <a class=\"mr-iid\" href=\"#{project_merge_request_path(mr_1.project, mr_1)}\">#{mr_1.to_reference} #{mr_1.title}</a>")
      end
    end

    context 'when pipeline is branch pipeline' do
      context 'when ref exists in the repository' do
        before do
          allow(pipeline).to receive(:ref_exists?) { true }
        end

        it 'returns a correct ref text' do
          is_expected.to eq("For <a class=\"ref-container gl-link\" href=\"#{project_commits_path(pipeline.project, pipeline.ref)}\">#{pipeline.ref}</a>")
        end

        context 'when ref contains malicious script' do
          let(:pipeline) { create(:ci_pipeline, ref: "<script>alter('1')</script>", project: project) }

          it 'does not include the malicious script' do
            is_expected.not_to include("<script>alter('1')</script>")
          end
        end
      end

      context 'when ref does not exist in the repository' do
        before do
          allow(pipeline).to receive(:ref_exists?) { false }
        end

        it 'returns a correct ref text' do
          is_expected.to eq("For <span class=\"ref-name\">#{pipeline.ref}</span>")
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

  describe '#link_to_merge_request' do
    subject { presenter.link_to_merge_request }

    context 'with a related merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_project: project) }
      let(:pipeline) { merge_request.all_pipelines.take }

      it 'returns a correct link' do
        is_expected.to include(project_merge_request_path(project, merge_request))
      end
    end

    context 'when pipeline is branch pipeline' do
      it { is_expected.to be_nil }
    end
  end

  describe '#link_to_merge_request_source_branch' do
    subject { presenter.link_to_merge_request_source_branch }

    context 'with a related merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_project: project) }
      let(:pipeline) { merge_request.all_pipelines.take }

      it 'returns a correct link' do
        is_expected.to include(project_commits_path(project, merge_request.source_branch))
      end
    end

    context 'when pipeline is branch pipeline' do
      it { is_expected.to be_nil }
    end
  end

  describe '#link_to_merge_request_target_branch' do
    subject { presenter.link_to_merge_request_target_branch }

    context 'with a related merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_project: project) }
      let(:pipeline) { merge_request.all_pipelines.take }

      it 'returns a correct link' do
        is_expected.to include(project_commits_path(project, merge_request.target_branch))
      end
    end

    context 'when pipeline is branch pipeline' do
      it { is_expected.to be_nil }
    end
  end

  describe '#triggered_by_path' do
    subject { presenter.triggered_by_path }

    context 'when the pipeline is a child ' do
      let(:upstream_pipeline) { create(:ci_pipeline) }
      let(:pipeline) { create(:ci_pipeline, child_of: upstream_pipeline) }
      let(:expected_path) { project_pipeline_path(upstream_pipeline.project, upstream_pipeline) }

      it 'returns the pipeline path' do
        expect(subject).to eq(expected_path)
      end
    end

    context 'when the pipeline is not a child ' do
      it 'returns the pipeline path' do
        expect(subject).to eq('')
      end
    end
  end

  describe '#all_related_merge_requests' do
    subject(:all_related_merge_requests) do
      presenter.send(:all_related_merge_requests)
    end

    it 'memoizes the returned relation' do
      expect(pipeline).to receive(:all_merge_requests_by_recency).exactly(1).time.and_call_original
      2.times { presenter.send(:all_related_merge_requests).count }
    end

    context 'for a branch pipeline with two open MRs' do
      let!(:one) { create(:merge_request, source_project: project, source_branch: pipeline.ref) }
      let!(:two) { create(:merge_request, source_project: project, source_branch: pipeline.ref, target_branch: 'fix') }

      it { is_expected.to contain_exactly(one, two) }
    end

    context 'permissions' do
      let_it_be_with_refind(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_project: project) }

      let(:pipeline) { merge_request.all_pipelines.take }

      shared_examples 'private merge requests' do
        context 'when not logged in' do
          let(:current_user) {}

          it { is_expected.to be_empty }
        end

        context 'when logged in as a non_member' do
          let(:current_user) { create(:user) }

          it { is_expected.to be_empty }
        end

        context 'when logged in as a guest' do
          let(:current_user) { create(:user) }

          before do
            project.add_guest(current_user)
          end

          it { is_expected.to be_empty }
        end

        context 'when logged in as a developer' do
          it { is_expected.to contain_exactly(merge_request) }
        end

        context 'when logged in as a maintainer' do
          let(:current_user) { create(:user) }

          before do
            project.add_maintainer(current_user)
          end

          it { is_expected.to contain_exactly(merge_request) }
        end
      end
    end
  end
end
