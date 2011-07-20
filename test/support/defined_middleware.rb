class DefinedMiddleware
  def initialize(app)
    @app = app
  end
  def call(env)
    path = env['PATH_INFO']
    if m = path.match(/^\/const\/(.*)/)
      const = m[1]
      answer = eval("defined?(#{const})")
      answer ||= "nil"
      return [200, {}, [answer]]
    else
      @app.call(env)
    end
  end
end