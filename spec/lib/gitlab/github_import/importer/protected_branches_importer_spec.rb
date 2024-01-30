# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ProtectedBranchesImporter, feature_category: :importers do
  subject(:importer) { described_class.new(project, client, parallel: parallel) }

  let(:project) { build(:project, id: 4, import_source: 'foo/bar') }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:parallel) { true }

  let(:branches) do
    branch = Struct.new(:name, :protection, keyword_init: true)
    protection = Struct.new(:enabled, keyword_init: true)

    [
      branch.new(name: 'main', protection: protection.new(enabled: false)),
      branch.new(name: 'staging', protection: protection.new(enabled: true)),
      branch.new(name: 'development', protection: nil) # when user has no admin right for this repo
    ]
  end

  let(:github_protection_rule) do
    response = Struct.new(:name, :url, :required_signatures, :enforce_admins, :required_linear_history,
      :allow_force_pushes, :allow_deletion, :block_creations, :required_conversation_resolution,
      :required_pull_request_reviews,
      keyword_init: true
    )
    required_signatures = Struct.new(:url, :enabled, keyword_init: true)
    enforce_admins = Struct.new(:url, :enabled, keyword_init: true)
    allow_option = Struct.new(:enabled, keyword_init: true)
    required_pull_request_reviews = Struct.new(
      :url, :dismissal_restrictions, :require_code_owner_reviews,
      keyword_init: true
    )
    response.new(
      name: 'main',
      url: 'https://example.com/branches/main/protection',
      required_signatures: required_signatures.new(
        url: 'https://example.com/branches/main/protection/required_signatures',
        enabled: false
      ),
      enforce_admins: enforce_admins.new(
        url: 'https://example.com/branches/main/protection/enforce_admins',
        enabled: false
      ),
      required_linear_history: allow_option.new(
        enabled: false
      ),
      allow_force_pushes: allow_option.new(
        enabled: false
      ),
      allow_deletion: allow_option.new(
        enabled: false
      ),
      block_creations: allow_option.new(
        enabled: true
      ),
      required_conversation_resolution: allow_option.new(
        enabled: false
      ),
      required_pull_request_reviews: required_pull_request_reviews.new(
        url: 'https://example.com/branches/main/protection/required_pull_request_reviews',
        dismissal_restrictions: {},
        require_code_owner_reviews: true
      )
    )
  end

  describe '#parallel?' do
    context 'when running in parallel mode' do
      it { expect(importer).to be_parallel }
    end

    context 'when running in sequential mode' do
      let(:parallel) { false }

      it { expect(importer).not_to be_parallel }
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports protected branches in parallel' do
        expect(importer).to receive(:parallel_import)

        importer.execute
      end
    end

    context 'when running in sequential mode' do
      let(:parallel) { false }

      it 'imports protected branches in sequence' do
        expect(importer).to receive(:sequential_import)

        importer.execute
      end
    end
  end

  describe '#sequential_import', :clean_gitlab_redis_shared_state do
    let(:parallel) { false }

    before do
      allow(client).to receive(:branches).and_return(branches)
      allow(client)
        .to receive(:branch_protection)
        .with(project.import_source, 'staging')
        .and_return(github_protection_rule)
        .once
    end

    it 'imports each protected branch in sequence' do
      protected_branch_importer = instance_double(Gitlab::GithubImport::Importer::ProtectedBranchImporter)

      expect(Gitlab::GithubImport::Importer::ProtectedBranchImporter)
        .to receive(:new)
          .with(
            an_instance_of(Gitlab::GithubImport::Representation::ProtectedBranch),
            project,
            client
          )
          .and_return(protected_branch_importer)

      expect(protected_branch_importer).to receive(:execute)
      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment).with(project, :protected_branch, :fetched)

      importer.sequential_import
    end
  end

  describe '#parallel_import', :clean_gitlab_redis_shared_state do
    before do
      allow(client).to receive(:branches).and_return(branches)
      allow(client)
        .to receive(:branch_protection)
        .with(project.import_source, 'staging')
        .and_return(github_protection_rule)
        .once
    end

    it 'imports each protected branch in parallel' do
      expect(Gitlab::GithubImport::ImportProtectedBranchWorker)
        .to receive(:perform_in)
        .with(an_instance_of(Float), project.id, an_instance_of(Hash), an_instance_of(String))

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment).with(project, :protected_branch, :fetched)

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end
  end

  describe '#each_object_to_import', :clean_gitlab_redis_shared_state do
    let(:branch_struct) { Struct.new(:protection, :name, :url, keyword_init: true) }
    let(:protection_struct) { Struct.new(:enabled, keyword_init: true) }
    let(:protected_branch) { branch_struct.new(name: 'main', protection: protection_struct.new(enabled: true)) }
    let(:second_protected_branch) { branch_struct.new(name: 'fix', protection: protection_struct.new(enabled: true)) }
    let(:unprotected_branch) { branch_struct.new(name: 'staging', protection: protection_struct.new(enabled: false)) }
    # when user has no admin rights on repo
    let(:unknown_protection_branch) { branch_struct.new(name: 'development', protection: nil) }

    let(:page_counter) { instance_double(Gitlab::Import::PageCounter) }

    before do
      allow(client).to receive(:branches).with(project.import_source)
        .and_return([protected_branch, second_protected_branch, unprotected_branch, unknown_protection_branch])
      allow(client).to receive(:branch_protection)
        .with(project.import_source, anything)
        .and_return(github_protection_rule)
      allow(Gitlab::GithubImport::ObjectCounter).to receive(:increment)
        .with(project, :protected_branch, :fetched)
    end

    it 'imports each protected branch page by page' do
      subject.each_object_to_import do |object|
        expect(object).to eq github_protection_rule
      end
      expect(Gitlab::GithubImport::ObjectCounter).to have_received(:increment).twice
    end

    context 'when protected branch is already processed' do
      it "doesn't process this branch" do
        subject.mark_as_imported(protected_branch)
        subject.mark_as_imported(second_protected_branch)

        subject.each_object_to_import {}
        expect(Gitlab::GithubImport::ObjectCounter).not_to have_received(:increment)
      end
    end
  end

  describe '#importer_class' do
    it { expect(importer.importer_class).to eq Gitlab::GithubImport::Importer::ProtectedBranchImporter }
  end

  describe '#representation_class' do
    it { expect(importer.representation_class).to eq Gitlab::GithubImport::Representation::ProtectedBranch }
  end

  describe '#sidekiq_worker_class' do
    it { expect(importer.sidekiq_worker_class).to eq Gitlab::GithubImport::ImportProtectedBranchWorker }
  end

  describe '#object_type' do
    it { expect(importer.object_type).to eq :protected_branch }
  end

  describe '#collection_method' do
    it { expect(importer.collection_method).to eq :protected_branches }
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the ID of the given protected branch' do
      expect(importer.id_for_already_imported_cache(github_protection_rule)).to eq('main')
    end
  end

  describe '#collection_options' do
    it 'returns an empty Hash' do
      # For large projects (e.g. kubernetes/kubernetes) GitHub's API may produce
      # HTTP 500 errors when using explicit sorting options, regardless of what
      # order you sort in. Not using any sorting options at all allows us to
      # work around this.
      expect(importer.collection_options).to eq({})
    end
  end
end
