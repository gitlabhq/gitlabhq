# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationContext, feature_category: :shared do
  describe '.allowed_job_keys' do
    it 'includes known keys but omits Web-specific keys' do
      expect(described_class.allowed_job_keys).to include(:user, :user_id, :project, :root_namespace, :client_id)
      expect(described_class.allowed_job_keys).not_to include(
        :auth_fail_reason,
        :auth_fail_token_id,
        :auth_fail_requested_scopes,
        :http_router_rule_action,
        :http_router_rule_type
      )
    end
  end

  describe '.with_context' do
    it 'yields the block' do
      expect { |b| described_class.with_context({}, &b) }.to yield_control
    end

    it 'passes the expected context on to labkit' do
      user = build(:user)
      project = build(:project)
      fake_proc = duck_type(:call)
      expected_context = hash_including(user: fake_proc, project: fake_proc, root_namespace: fake_proc)

      expect(Labkit::Context).to receive(:with_context).with(expected_context)

      described_class.with_context(
        user: user,
        project: project,
        namespace: build(:namespace)) {}
    end

    it 'raises an error when passing invalid options' do
      expect { described_class.with_context(no: 'option') {} }.to raise_error(ArgumentError)
    end
  end

  describe '.with_raw_context' do
    it 'yields the block' do
      expect { |b| described_class.with_raw_context({}, &b) }.to yield_control
    end

    it 'passes the attributes unaltered on to labkit' do
      attrs = { foo: :bar }

      expect(Labkit::Context).to receive(:with_context).with(attrs)

      described_class.with_raw_context(attrs) {}
    end
  end

  describe '.push' do
    it 'passes the expected context on to labkit' do
      fake_proc = duck_type(:call)
      expected_context = { user: fake_proc, user_id: fake_proc, client_id: fake_proc }

      expect(Labkit::Context).to receive(:push).with(expected_context)

      described_class.push(user: build(:user))
    end

    it 'raises an error when passing invalid options' do
      expect { described_class.push(no: 'option') }.to raise_error(ArgumentError)
    end
  end

  describe '.current_context_include?' do
    it 'returns true if the key was present in the context' do
      described_class.with_context(caller_id: "Hello") do
        expect(described_class.current_context_include?(:caller_id)).to be(true)
      end
    end

    it 'returns false if the key was not present in the current context' do
      expect(described_class.current_context_include?(:caller_id)).to be(false)
    end
  end

  describe '.current_context_attribute' do
    it 'returns the raw attribute value' do
      described_class.with_context(caller_id: "Hello") do
        expect(described_class.current_context_attribute(:caller_id)).to be('Hello')
      end
    end

    it 'returns the attribute value with meta prefix' do
      described_class.with_context(feature_category: "secure") do
        expect(described_class.current_context_attribute('meta.feature_category')).to be('secure')
      end
    end

    it 'returns nil if the key was not present in the current context' do
      expect(described_class.current_context_attribute(:caller_id)).to be(nil)
    end
  end

  describe '#to_lazy_hash' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:namespace) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: namespace) }

    def result(context)
      context.to_lazy_hash.transform_values { |v| v.respond_to?(:call) ? v.call : v }
    end

    it 'does not call the attributes until needed' do
      fake_proc = double('Proc')

      expect(fake_proc).not_to receive(:call)

      described_class.new(user: fake_proc, project: fake_proc, namespace: fake_proc).to_lazy_hash
    end

    it 'correctly loads the expected values when they are wrapped in a block' do
      context = described_class.new(user: -> { user }, project: -> { project }, namespace: -> { subgroup })

      expect(result(context)).to include(
        user: user.username,
        user_id: user.id,
        project: project.full_path,
        root_namespace: namespace.full_path
      )
    end

    it 'correctly loads the expected values when passed directly' do
      context = described_class.new(user: user, project: project, namespace: subgroup)

      expect(result(context)).to include(
        user: user.username,
        user_id: user.id,
        project: project.full_path,
        root_namespace: namespace.full_path
      )
    end

    it 'falls back to a projects namespace when a project is passed but no namespace' do
      context = described_class.new(project: project)

      expect(result(context)).to include(
        project: project.full_path,
        root_namespace: project.full_path_components.first
      )
    end

    it 'contains known keys' do
      context = described_class.new(project: project)

      # Make sure all possible keys would be included
      allow(context).to receive_message_chain(:set_values, :include?).and_return(true)

      # If a newly added key is added to the context hash, we need to list it in
      # the known keys constant. This spec ensures that we do.
      expect(context.to_lazy_hash.keys).to contain_exactly(*described_class.known_keys)
    end

    describe 'setting the client' do
      let_it_be(:remote_ip) { '127.0.0.1' }
      let_it_be(:runner) { create(:ci_runner) }
      let_it_be(:job) { create(:ci_build, :pending, :queued, user: user, project: project) }
      let_it_be(:options) { { remote_ip: remote_ip, runner: runner, user: user, job: job } }

      using RSpec::Parameterized::TableSyntax

      where(:provided_options, :client) do
        [:remote_ip]                 | :remote_ip
        [:remote_ip, :runner]        | :runner
        [:remote_ip, :runner, :user] | :runner
        [:remote_ip, :user]          | :user
        [:job]                       | :user
      end

      with_them do
        it 'sets the client_id to the expected value' do
          context = described_class.new(**options.slice(*provided_options))

          client_id = case client
                      when :remote_ip then "ip/#{remote_ip}"
                      when :runner then "runner/#{runner.id}"
                      when :user then "user/#{user.id}"
                      end

          expect(result(context)[:client_id]).to eq(client_id)
        end
      end
    end

    context 'when using a runner project' do
      let_it_be(:owner_project) { create(:project) }
      let_it_be_with_reload(:runner) { create(:ci_runner, :project, projects: [owner_project]) }

      it 'sets project path from owner project' do
        context = described_class.new(runner: runner)

        expect(result(context)).to include(project: runner.owner.full_path)
      end

      context 'when the runner serves multiple projects' do
        before do
          create(:ci_runner_project, runner: runner, project: project)
        end

        it 'sets project path from owner project' do
          context = described_class.new(runner: runner)

          expect(result(context)).to include(project: runner.owner.full_path)
        end
      end
    end

    context 'when using an instance runner' do
      let_it_be(:runner) { create(:ci_runner, :instance) }

      it 'does not sets project path' do
        context = described_class.new(runner: runner)

        expect(result(context)).to include(project: nil)
      end
    end

    context 'when using job context' do
      let_it_be(:job) { create(:ci_build, :pending, :queued, user: user, project: project) }

      it 'sets expected values' do
        context = described_class.new(job: job)

        expect(result(context)).to include(job_id: job.id, project: project.full_path, pipeline_id: job.pipeline_id)
      end
    end

    context 'when using bulk import context' do
      it 'sets expected bulk_import_entity_id value' do
        context = described_class.new(bulk_import_entity_id: 1)

        expect(result(context)).to include(bulk_import_entity_id: 1)
      end
    end

    context 'when using organization context' do
      let_it_be(:organization) { create(:organization) }

      it 'sets the organization_id value' do
        context = described_class.new(organization: organization)

        expect(result(context)).to include(organization_id: organization.id)
      end
    end
  end

  describe '#use' do
    let(:context) { described_class.new(user: build(:user)) }

    it 'yields control' do
      expect { |b| context.use(&b) }.to yield_control
    end

    it 'passes the expected context on to labkit' do
      expect(Labkit::Context).to receive(:with_context).with(a_hash_including(user: duck_type(:call)))

      context.use {}
    end

    it 'does not cause queries' do
      context = described_class.new(project: create(:project), namespace: create(:group, :nested), user: create(:user))

      expect { context.use { Gitlab::ApplicationContext.current } }.not_to exceed_query_limit(0)
    end
  end
end
