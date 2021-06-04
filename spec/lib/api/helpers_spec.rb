# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers do
  using RSpec::Parameterized::TableSyntax

  subject { Class.new.include(described_class).new }

  describe '#current_user' do
    include Rack::Test::Methods

    let(:user) { build(:user, id: 42) }

    let(:helper) do
      Class.new(Grape::API::Instance) do
        helpers API::APIGuard::HelperMethods
        helpers API::Helpers
        format :json

        get 'user' do
          current_user ? { id: current_user.id } : { found: false }
        end

        get 'protected' do
          authenticate_by_gitlab_geo_node_token!
        end
      end
    end

    def app
      helper
    end

    before do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
    end

    it 'handles sticking when a user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .to receive(:stick_or_unstick).with(any_args, :user, 42)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'id' => user.id })
    end

    it 'does not handle sticking if no user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(nil)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware)
        .not_to receive(:stick_or_unstick)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'found' => false })
    end

    it 'returns the user if one could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'id' => user.id })
    end
  end

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

  describe '#find_project!' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private project without access' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(subject).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(subject).to receive(:not_found!)

        subject.find_project!(project.id)
      end
    end

    context 'when user is authenticated' do
      before do
        subject.instance_variable_set(:@current_user, user)
        subject.instance_variable_set(:@initial_current_user, user)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(subject.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end
    end

    context 'when user is not authenticated' do
      before do
        subject.instance_variable_set(:@current_user, nil)
        subject.instance_variable_set(:@initial_current_user, nil)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(subject.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end
    end
  end

  describe '#find_project!' do
    let_it_be(:project) { create(:project) }

    let(:user) { project.owner}

    before do
      allow(subject).to receive(:current_user).and_return(user)
      allow(subject).to receive(:authorized_project_scope?).and_return(true)
      allow(subject).to receive(:job_token_authentication?).and_return(false)
      allow(subject).to receive(:authenticate_non_public?).and_return(false)
    end

    shared_examples 'project finder' do
      context 'when project exists' do
        it 'returns requested project' do
          expect(subject.find_project!(existing_id)).to eq(project)
        end

        it 'returns nil' do
          expect(subject).to receive(:render_api_error!).with('404 Project Not Found', 404)
          expect(subject.find_project!(non_existing_id)).to be_nil
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
          expect(subject).to receive(:render_api_error!).with('404 Project Not Found', 404)

          subject.find_project!(non_existing_id)
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

  describe '#authorized_project_scope?' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:job) { create(:ci_build) }

    let(:send_authorized_project_scope) { subject.authorized_project_scope?(project) }

    where(:job_token_authentication, :route_setting, :feature_flag, :same_job_project, :expected_result) do
      false | false | false | false | true
      false | false | false | true  | true
      false | false | true  | false | true
      false | false | true  | true  | true
      false | true  | false | false | true
      false | true  | false | true  | true
      false | true  | true  | false | true
      false | true  | true  | true  | true
      true  | false | false | false | true
      true  | false | false | true  | true
      true  | false | true  | false | true
      true  | false | true  | true  | true
      true  | true  | false | false | false
      true  | true  | false | true  | false
      true  | true  | true  | false | false
      true  | true  | true  | true  | true
    end

    with_them do
      before do
        allow(subject).to receive(:job_token_authentication?).and_return(job_token_authentication)
        allow(subject).to receive(:route_authentication_setting).and_return(job_token_scope: route_setting ? :project : nil)
        allow(subject).to receive(:current_authenticated_job).and_return(job)
        allow(job).to receive(:project).and_return(same_job_project ? project : other_project)

        stub_feature_flags(ci_job_token_scope: false)
        stub_feature_flags(ci_job_token_scope: project) if feature_flag
      end

      it 'returns the expected result' do
        expect(send_authorized_project_scope).to eq(expected_result)
      end
    end
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

  describe '#increment_unique_values' do
    let(:value) { '9f302fea-f828-4ca9-aef4-e10bd723c0b3' }
    let(:event_name) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    it 'tracks redis hll event' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(event_name, values: value)

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

  describe '#present_disk_file!' do
    let_it_be(:dummy_class) do
      Class.new do
        attr_reader :headers
        alias_method :header, :headers

        def initialize
          @headers = {}
        end
      end
    end

    let(:dummy_instance) { dummy_class.include(described_class).new }
    let(:path) { '/tmp/file.txt' }
    let(:filename) { 'file.txt' }

    subject { dummy_instance.present_disk_file!(path, filename) }

    before do
      expect(dummy_instance).to receive(:content_type).with('application/octet-stream')
    end

    context 'with X-Sendfile supported' do
      before do
        dummy_instance.headers['X-Sendfile-Type'] = 'X-Sendfile'
      end

      it 'sends the file using X-Sendfile' do
        expect(dummy_instance).to receive(:body).with('')

        subject

        expect(dummy_instance.headers['X-Sendfile']).to eq(path)
      end
    end

    context 'without X-Sendfile supported' do
      it 'sends the file' do
        expect(dummy_instance).to receive(:sendfile).with(path)

        subject
      end
    end
  end
end
