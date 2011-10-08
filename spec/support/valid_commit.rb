module ValidCommit
  ID = "eaffbe556ec3a8dc84ef15892a9f12d84dde7e1d"
  MESSAGE = "style"
  AUTHOR_FULL_NAME = "Dmitriy Zaporozhets"

  FILES = [".gitignore", ".rspec", ".rvmrc", "Gemfile", "Gemfile.lock", "LICENSE", "README.rdoc", "Rakefile", "app", "config.ru", "config", "db", "doc", "lib", "log", "public", "script", "spec", "vendor"]
  FILES_COUNT = 19

  C_FILE_PATH = "app/models"
  C_FILES = [".gitkeep", "project.rb", "user.rb"]

  BLOB_FILE = <<-blob
<div class="span-14 colborder">
  <h2>Tree / <%= link_to "Commits", project_commits_path(@project) %></h2>
  <%= render :partial => "tree", :locals => {:repo => @repo, :commit => @commit, :tree => @commit.tree} %>
</div>

<div class="span-8 right">
  <%= render "side_panel" %>
</div>
blob

  BLOB_FILE_PATH = "app/views/projects/show.html.erb"
end

