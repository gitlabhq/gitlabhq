# frozen_string_literal: true

RSpec.shared_context 'basic Go module' do
  let_it_be(:user, freeze: false) { create :user }
  let_it_be(:project, freeze: false) { create :project_empty_repo, creator: user, path: 'my-go-lib' }

  let_it_be(:commit_v1_0_0, freeze: false) { create :go_module_commit, :files,   project: project, tag: 'v1.0.0', files: { 'README.md' => 'Hi' }        }
  let_it_be(:commit_v1_0_1, freeze: false) { create :go_module_commit, :module,  project: project, tag: 'v1.0.1'                                        }
  let_it_be(:commit_v1_0_2, freeze: false) { create :go_module_commit, :package, project: project, tag: 'v1.0.2', path: 'pkg'                           }
  let_it_be(:commit_v1_0_3, freeze: false) { create :go_module_commit, :module,  project: project, tag: 'v1.0.3', name: 'mod'                           }
  let_it_be(:commit_file_y, freeze: false) { create :go_module_commit, :files,   project: project,                files: { 'y.go' => "package a\n" }    }
  let_it_be(:commit_mod_v2, freeze: false) { create :go_module_commit, :module,  project: project,                name: 'v2'                            }
  let_it_be(:commit_v2_0_0, freeze: false) { create :go_module_commit, :files,   project: project, tag: 'v2.0.0', files: { 'v2/x.go' => "package a\n" } }
end
