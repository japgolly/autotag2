class Object
  def deep_freeze
    respond_to?(:freeze) ? freeze : self
  end
end

class Array
  def deep_freeze
    each {|e| e.deep_freeze}
    freeze
  end
  
  def rand
    empty? ? nil : self[Kernel::rand(size)]
  end
end

class Hash
  def assert_mutually_exclusive_keys(*keys)
    c= 0
    keys.each {|k| c+=1 if has_key?(k)}
    raise "Only one of the following keys may be used: '#{keys.join(', ')}'" if c>1
  end
  
  def -(v)
    r= clone
    case v
    when Array then v
    when Hash then v.keys
    else [v]
    end.each {|k| r.delete k}
    r
  end
  
  def deep_freeze
    each {|k,v|
      k.deep_freeze
      v.deep_freeze
    }
    freeze
  end
  
end
