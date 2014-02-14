module ValidCommit
  ID = "8470d70da67355c9c009e4401746b1d5410af2e3"
  MESSAGE = "notes controller refactored"
  AUTHOR_FULL_NAME = "Dmitriy Zaporozhets"
  AUTHOR_EMAIL = "dmitriy.zaporozhets@gmail.com"

  FILES = [".foreman", ".gitignore", ".rails_footnotes", ".rspec", ".travis.yml", "CHANGELOG", "Gemfile", "Gemfile.lock", "LICENSE", "Procfile", "Procfile.production", "README.md", "Rakefile", "VERSION", "app", "config.ru", "config", "db", "doc", "lib", "log", "public", "resque.sh", "script", "spec", "vendor"]
  FILES_COUNT = 26

  C_FILE_PATH = "app/models"
  C_FILES = [".gitkeep", "ability.rb", "commit.rb", "issue.rb", "key.rb", "mailer_observer.rb", "merge_request.rb", "note.rb", "project.rb", "protected_branch.rb", "repository.rb", "snippet.rb", "tree.rb", "user.rb", "users_project.rb", "web_hook.rb", "wiki.rb"]

  BLOB_FILE = %{%h3= @key.title\n%hr\n%pre= @key.key\n.actions\n  = link_to 'Remove', @key, :confirm => 'Are you sure?', :method => :delete, :class => \"btn danger delete-key\"\n\n\n}
  BLOB_FILE_PATH = "app/views/keys/show.html.haml"
end

