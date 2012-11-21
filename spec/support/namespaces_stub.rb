require 'namespace'
require 'gitlab/project_mover'

class Namespace
  def ensure_dir_exist
    true
  end

  def move_dir
    true
  end
end

#class Gitlab::ProjectMover
  #def execute
    #true
  #end
#end
