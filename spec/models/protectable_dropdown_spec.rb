# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectableDropdown do
  subject(:dropdown) { described_class.new(project, ref_type) }

  let_it_be_with_reload(:project) { create(:project, :repository) }

  describe 'initialize' do
    it 'raises ArgumentError for invalid ref type' do
      expect { described_class.new(double, :foo) }
        .to raise_error(ArgumentError, "invalid ref type `foo`")
    end
  end

  shared_examples 'protectable_ref_names' do
    context 'when project repository is not empty' do
      it 'includes elements matching a protected ref wildcard' do
        is_expected.to include(matching_ref)

        factory = ref_type == :branches ? :protected_branch : :protected_tag

        create(factory, name: "#{matching_ref[0]}*", project: project)

        subject = described_class.new(project.reload, ref_type)

        expect(subject.protectable_ref_names).to include(matching_ref)
      end
    end

    context 'when project repository is empty' do
      let(:project) { create(:project) }

      it 'returns empty list' do
        is_expected.to be_empty
      end
    end
  end

  describe '#protectable_ref_names' do
    subject { dropdown.protectable_ref_names }

    context 'for branches' do
      let(:ref_type) { :branches }
      let(:matching_ref) { 'feature' }

      before do
        create(:protected_branch, project: project, name: 'master')
      end

      it { is_expected.to include(matching_ref) }
      it { is_expected.not_to include('master') }

      it_behaves_like 'protectable_ref_names'
    end

    context 'for tags' do
      let(:ref_type) { :tags }
      let(:matching_ref) { 'v1.0.0' }

      before do
        create(:protected_tag, project: project, name: 'v1.1.0')
      end

      it { is_expected.to include(matching_ref) }
      it { is_expected.not_to include('v1.1.0') }

      it_behaves_like 'protectable_ref_names'
    end
  end

  describe '#paginated_protectable_ref_names' do
    subject(:result) { dropdown.paginated_protectable_ref_names(limit: limit, page_token: page_token, search: search) }

    let(:ref_type) { :branches }
    let(:limit) { 3 }
    let(:page_token) { nil }
    let(:search) { nil }

    context 'with default params' do
      it 'returns branch names and next_cursor', :aggregate_failures do
        expect(result[:names]).to be_present
        expect(result[:names].length).to be <= limit
      end
    end

    context 'when a branch is protected' do
      before do
        create(:protected_branch, project: project, name: 'master')
      end

      it 'excludes the protected branch' do
        expect(result[:names]).not_to include('master')
      end
    end

    context 'when non-wildcard protected branches exceed MAX_EXCLUDE_PATTERNS' do
      let(:limit) { 100 }

      before do
        stub_const("#{described_class}::MAX_EXCLUDE_PATTERNS", 2)
        create(:protected_branch, project: project, name: 'master')
        create(:protected_branch, project: project, name: 'feature')
        create(:protected_branch, project: project, name: 'fix')
      end

      it 'caps the exclude list sent to Gitaly' do
        finder = instance_double(Gitlab::Git::Finders::RefsFinder, execute: [], next_cursor: nil)

        expect(Gitlab::Git::Finders::RefsFinder).to receive(:new).with(
          anything,
          hash_including(exclude_ref_names: have_attributes(size: 2))
        ).and_return(finder)

        result
      end
    end

    context 'with search' do
      let(:search) { 'feature' }
      let(:limit) { 100 }

      it 'filters branches by search term' do
        expect(result[:names]).to be_present
        expect(result[:names]).to all(include('feature'))
      end
    end

    context 'with a wildcard protected branch' do
      let(:limit) { 100 }

      before do
        create(:protected_branch, project: project, name: 'feature*')
      end

      it 'still includes branches matching the wildcard' do
        expect(result[:names]).to include('feature')
      end
    end

    context 'with both exact-match and wildcard protected branches' do
      let(:limit) { 100 }

      before do
        create(:protected_branch, project: project, name: 'master')
        create(:protected_branch, project: project, name: 'feature*')
      end

      it 'excludes exact-match but includes wildcard-matched branches', :aggregate_failures do
        expect(result[:names]).not_to include('master')
        expect(result[:names]).to include('feature')
      end
    end

    context 'when project repository is empty' do
      let(:project) { create(:project) }

      it 'returns empty results', :aggregate_failures do
        expect(result[:names]).to be_empty
        expect(result[:next_cursor]).to be_nil
      end
    end

    context 'when ref_type is tags' do
      let(:ref_type) { :tags }

      it 'returns tag names', :aggregate_failures do
        expect(result[:names]).to be_present
        expect(result[:names].length).to be <= limit
      end

      context 'when a tag is protected' do
        before do
          create(:protected_tag, project: project, name: 'v1.1.0')
        end

        it 'excludes the protected tag' do
          expect(result[:names]).not_to include('v1.1.0')
        end
      end
    end

    context 'with next_cursor' do
      let(:limit) { 1 }

      it 'returns a next_cursor when more results exist' do
        expect(result[:next_cursor]).to be_present
      end
    end

    context 'with a protected branch whose name is a prefix of other branch names' do
      let(:project) { create(:project, :repository) }
      let(:limit) { 100 }

      before do
        project.repository.add_branch(project.owner, 'release', 'master')
        project.repository.add_branch(project.owner, 'release-v2', 'master')
        project.repository.add_branch(project.owner, 'releases', 'master')
        create(:protected_branch, project: project, name: 'release')
      end

      it 'excludes only the exact match, not similarly-named branches', :aggregate_failures do
        expect(result[:names]).not_to include('release')
        expect(result[:names]).to include('release-v2')
        expect(result[:names]).to include('releases')
      end
    end

    context 'with search and a wildcard protected branch' do
      let(:search) { 'feature' }
      let(:limit) { 100 }

      before do
        create(:protected_branch, project: project, name: 'feature*')
      end

      it 'still includes branches matching the wildcard in search results' do
        expect(result[:names]).to be_present
        expect(result[:names]).to include('feature')
        expect(result[:names]).to all(include('feature'))
      end
    end
  end

  describe '#array' do
    subject { dropdown.array }

    context 'for branches' do
      let(:ref_type) { :branches }

      it { is_expected.to include(id: 'feature', text: 'feature', title: 'feature') }
    end

    context 'for tags' do
      let(:ref_type) { :tags }

      it { is_expected.to include(id: 'v1.0.0', text: 'v1.0.0', title: 'v1.0.0') }
    end
  end
end
