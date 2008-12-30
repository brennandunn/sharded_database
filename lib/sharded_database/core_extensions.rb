class Object
  
  def temporarily_remove(method, &block)
    alias_method "original_#{method}", method
    undef_method(method)
    return yield
  ensure
    alias_method method, "original_#{method}"
  end
  
end