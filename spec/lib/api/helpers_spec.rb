# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers do
  subject { Class.new.include(described_class).new }

  describe '#find_project' do
    let(:project) { create(:project) }

    shared_examples 'project finder' do
      context 'when project exists' do
        it 'returns requested project' do
          expect(subject.find_project(existing_id)).to eq(project)
        end

        it 'returns nil' do
          expect(subject.find_project(non_existing_id)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { project.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'project finder'
    end

    context 'when PATH is used as an argument' do
      let(:existing_id) { project.full_path }
      let(:non_existing_id) { 'something/else' }

      it_behaves_like 'project finder'

      context 'with an invalid PATH' do
        let(:non_existing_id) { 'undefined' } # path without slash

        it_behaves_like 'project finder'

        it 'does not hit the database' do
          expect(Project).not_to receive(:find_by_full_path)

          subject.find_project(non_existing_id)
        end
      end
    end
  end

  describe '#find_namespace' do
    let(:namespace) { create(:namespace) }

    shared_examples 'namespace finder' do
      context 'when namespace exists' do
        it 'returns requested namespace' do
          expect(subject.find_namespace(existing_id)).to eq(namespace)
        end
      end

      context "when namespace doesn't exists" do
        it 'returns nil' do
          expect(subject.find_namespace(non_existing_id)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { namespace.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'namespace finder'
    end

    context 'when PATH is used as an argument' do
      let(:existing_id) { namespace.path }
      let(:non_existing_id) { 'non-existing-path' }

      it_behaves_like 'namespace finder'
    end
  end

  shared_examples 'user namespace finder' do
    let(:user1) { create(:user) }

    before do
      allow(subject).to receive(:current_user).and_return(user1)
      allow(subject).to receive(:header).and_return(nil)
      allow(subject).to receive(:not_found!).and_raise('404 Namespace not found')
    end

    context 'when namespace is group' do
      let(:namespace) { create(:group) }

      context 'when user has access to group' do
        before do
          namespace.add_guest(user1)
          namespace.save!
        end

        it 'returns requested namespace' do
          expect(namespace_finder).to eq(namespace)
        end
      end

      context "when user doesn't have access to group" do
        it 'raises not found error' do
          expect { namespace_finder }.to raise_error(RuntimeError, '404 Namespace not found')
        end
      end
    end

    context "when namespace is user's personal namespace" do
      let(:namespace) { create(:namespace) }

      context 'when user owns the namespace' do
        before do
          namespace.owner = user1
          namespace.save!
        end

        it 'returns requested namespace' do
          expect(namespace_finder).to eq(namespace)
        end
      end

      context "when user doesn't own the namespace" do
        it 'raises not found error' do
          expect { namespace_finder }.to raise_error(RuntimeError, '404 Namespace not found')
        end
      end
    end
  end

  describe '#find_namespace!' do
    let(:namespace_finder) do
      subject.find_namespace!(namespace.id)
    end

    it_behaves_like 'user namespace finder'
  end

  describe '#send_git_blob' do
    let(:repository) { double }
    let(:blob) { double(name: 'foobar') }

    let(:send_git_blob) do
      subject.send(:send_git_blob, repository, blob)
    end

    before do
      allow(subject).to receive(:env).and_return({})
      allow(subject).to receive(:content_type)
      allow(subject).to receive(:header).and_return({})
      allow(Gitlab::Workhorse).to receive(:send_git_blob)
    end

    it 'sets Gitlab::Workhorse::DETECT_HEADER header' do
      expect(send_git_blob[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
    end

    context 'content disposition' do
      context 'when blob name is null' do
        let(:blob) { double(name: nil) }

        it 'returns only the disposition' do
          expect(send_git_blob['Content-Disposition']).to eq 'inline'
        end
      end

      context 'when blob name is not null' do
        it 'returns disposition with the blob name' do
          expect(send_git_blob['Content-Disposition']).to eq %q(inline; filename="foobar"; filename*=UTF-8''foobar)
        end
      end
    end
  end

  describe '#track_event' do
    it "creates a gitlab tracking event", :snowplow do
      subject.track_event('my_event', category: 'foo')

      expect_snowplow_event(category: 'foo', action: 'my_event')
    end

    it "logs an exception" do
      expect(Gitlab::AppLogger).to receive(:warn).with(/Tracking event failed/)

      subject.track_event('my_event', category: nil)
    end
  end

  describe '#increment_unique_values' do
    let(:value) { '9f302fea-f828-4ca9-aef4-e10bd723c0b3' }
    let(:event_name) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }
    let(:feature) { "usage_data_#{event_name}" }

    before do
      skip_feature_flags_yaml_validation
    end

    context 'with feature enabled' do
      before do
        stub_feature_flags(feature => true)
      end

      it 'tracks redis hll event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(value, event_name)

        subject.increment_unique_values(event_name, value)
      end

      it 'logs an exception for unknown event' do
        expect(Gitlab::AppLogger).to receive(:warn).with("Redis tracking event failed for event: #{unknown_event}, message: Unknown event #{unknown_event}")

        subject.increment_unique_values(unknown_event, value)
      end

      it 'does not track event for nil values' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        subject.increment_unique_values(unknown_event, nil)
      end
    end

    context 'with feature disabled' do
      before do
        stub_feature_flags(feature => false)
      end

      it 'does not track event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        subject.increment_unique_values(event_name, value)
      end
    end
  end

  describe '#order_options_with_tie_breaker' do
    subject { Class.new.include(described_class).new.order_options_with_tie_breaker }

    before do
      allow_any_instance_of(described_class).to receive(:params).and_return(params)
    end

    context 'with non-id order given' do
      context 'with ascending order' do
        let(:params) { { order_by: 'name', sort: 'asc' } }

        it 'adds id based ordering with same direction as primary order' do
          is_expected.to eq({ 'name' => 'asc', 'id' => 'asc' })
        end
      end

      context 'with descending order' do
        let(:params) { { order_by: 'name', sort: 'desc' } }

        it 'adds id based ordering with same direction as primary order' do
          is_expected.to eq({ 'name' => 'desc', 'id' => 'desc' })
        end
      end
    end

    context 'with non-id order but no direction given' do
      let(:params) { { order_by: 'name' } }

      it 'adds ID ASC order' do
        is_expected.to eq({ 'name' => nil, 'id' => 'asc' })
      end
    end

    context 'with id order given' do
      let(:params) { { order_by: 'id', sort: 'asc' } }

      it 'does not add an additional order' do
        is_expected.to eq({ 'id' => 'asc' })
      end
    end
  end

  describe "#destroy_conditionally!" do
    let!(:project) { create(:project) }

    context 'when unmodified check passes' do
      before do
        allow(subject).to receive(:check_unmodified_since!).with(project.updated_at).and_return(true)
      end

      it 'destroys given project' do
        allow(subject).to receive(:status).with(204)
        allow(subject).to receive(:body).with(false)
        expect(project).to receive(:destroy).and_call_original

        expect { subject.destroy_conditionally!(project) }.to change(Project, :count).by(-1)
      end
    end

    context 'when unmodified check fails' do
      before do
        allow(subject).to receive(:check_unmodified_since!).with(project.updated_at).and_throw(:error)
      end

      # #destroy_conditionally! uses Grape errors which Ruby-throws a symbol, shifting execution to somewhere else.
      # Since this spec isn't in the Grape context, we need to simulate this ourselves.
      # Grape throws here: https://github.com/ruby-grape/grape/blob/470f80cd48933cdf11d4c1ee02cb43e0f51a7300/lib/grape/dsl/inside_route.rb#L168-L171
      # And catches here: https://github.com/ruby-grape/grape/blob/cf57d250c3d77a9a488d9f56918d62fd4ac745ff/lib/grape/middleware/error.rb#L38-L40
      it 'does not destroy given project' do
        expect(project).not_to receive(:destroy)

        expect { subject.destroy_conditionally!(project) }.to throw_symbol(:error).and change { Project.count }.by(0)
      end
    end
  end

  describe "#check_unmodified_since!" do
    let(:unmodified_since_header) { Time.now.change(usec: 0) }

    before do
      allow(subject).to receive(:headers).and_return('If-Unmodified-Since' => unmodified_since_header.to_s)
    end

    context 'when last modified is later than header value' do
      it 'renders error' do
        expect(subject).to receive(:render_api_error!)

        subject.check_unmodified_since!(unmodified_since_header + 1.hour)
      end
    end

    context 'when last modified is earlier than header value' do
      it 'does not render error' do
        expect(subject).not_to receive(:render_api_error!)

        subject.check_unmodified_since!(unmodified_since_header - 1.hour)
      end
    end

    context 'when last modified is equal to header value' do
      it 'does not render error' do
        expect(subject).not_to receive(:render_api_error!)

        subject.check_unmodified_since!(unmodified_since_header)
      end
    end

    context 'when there is no header value present' do
      let(:unmodified_since_header) { nil }

      it 'does not render error' do
        expect(subject).not_to receive(:render_api_error!)

        subject.check_unmodified_since!(Time.now)
      end
    end

    context 'when header value is not a valid time value' do
      let(:unmodified_since_header) { "abcd" }

      it 'does not render error' do
        expect(subject).not_to receive(:render_api_error!)

        subject.check_unmodified_since!(Time.now)
      end
    end
  end
end
