class NullContext
  def initialize(params: {})
    @params = params
  end

  attr_reader :params

  def created(*args)
  end
end
