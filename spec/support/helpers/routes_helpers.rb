module RoutesHelpers
  def fake_routes(&block)
    @routes = @routes.dup
    @routes.formatter.clear
    ActionDispatch::Routing::Mapper.new(@routes).instance_exec(&block)
  end
end
