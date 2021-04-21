# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::ModuleVersion, type: :model do
  include_context 'basic Go module'

  let_it_be(:mod) { create :go_module, project: project }

  shared_examples '#files' do |desc, *entries|
    it "returns #{desc}" do
      actual = version.files.map { |x| x }.to_set
      expect(actual).to eq(entries.to_set)
    end
  end

  shared_examples '#archive' do |desc, *entries|
    it "returns an archive of #{desc}" do
      expected = entries.map { |e| "#{version.full_name}/#{e}" }.to_set

      actual = Set[]
      Zip::InputStream.open(StringIO.new(version.archive.string)) do |zip|
        while (entry = zip.get_next_entry)
          actual.add(entry.name)
        end
      end

      expect(actual).to eq(expected)
    end
  end

  describe '#name' do
    context 'with ref and name specified' do
      let_it_be(:version) { create :go_module_version, mod: mod, name: 'foobar', commit: project.repository.head_commit, ref: project.repository.find_tag('v1.0.0') }

      it('returns that name') { expect(version.name).to eq('foobar') }
    end

    context 'with ref specified and name unspecified' do
      let_it_be(:version) { create :go_module_version, mod: mod, commit: project.repository.head_commit, ref: project.repository.find_tag('v1.0.0') }

      it('returns the name of the ref') { expect(version.name).to eq('v1.0.0') }
    end

    context 'with ref and name unspecified' do
      let_it_be(:version) { create :go_module_version, mod: mod, commit: project.repository.head_commit }

      it('returns nil') { expect(version.name).to eq(nil) }
    end
  end

  describe '#gomod' do
    context 'with go.mod missing' do
      let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.0' }

      it('returns nil') { expect(version.gomod).to eq(nil) }
    end

    context 'with go.mod present' do
      let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.1' }

      it('returns the contents of go.mod') { expect(version.gomod).to eq("module #{mod.name}\n") }
    end
  end

  describe '#files' do
    context 'with a root module' do
      context 'with an empty module path' do
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.2' }

        it_behaves_like '#files', 'all the files', 'README.md', 'go.mod', 'a.go', 'pkg/b.go'
      end
    end

    context 'with a root module and a submodule' do
      context 'with an empty module path' do
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.3' }

        it_behaves_like '#files', 'files excluding the submodule', 'README.md', 'go.mod', 'a.go', 'pkg/b.go'
      end

      context 'with the submodule\'s path' do
        let_it_be(:mod) { create :go_module, project: project, path: 'mod' }
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.3' }

        it_behaves_like '#files', 'the submodule\'s files', 'mod/go.mod', 'mod/a.go'
      end
    end
  end

  describe '#archive' do
    context 'with a root module' do
      context 'with an empty module path' do
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.2' }

        it_behaves_like '#archive', 'all the files', 'README.md', 'go.mod', 'a.go', 'pkg/b.go'
      end
    end

    context 'with a root module and a submodule' do
      context 'with an empty module path' do
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.3' }

        it_behaves_like '#archive', 'files excluding the submodule', 'README.md', 'go.mod', 'a.go', 'pkg/b.go'
      end

      context 'with the submodule\'s path' do
        let_it_be(:mod) { create :go_module, project: project, path: 'mod' }
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.3' }

        it_behaves_like '#archive', 'the submodule\'s files', 'go.mod', 'a.go'
      end
    end
  end
end
