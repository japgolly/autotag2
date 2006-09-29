#===========================
# Object

class Object
  def deep_clone
    case self
    when Fixnum,Bignum,Float,NilClass,FalseClass,TrueClass,Continuation,Symbol
      self
    else
      respond_to?(:clone) ? clone : (respond_to?(:dup) ? dup : self)
    end
  end
  
  def deep_freeze
    respond_to?(:freeze) ? freeze : self
  end
end


#===========================
# Collections

class Array
  def deep_clone
    map{|e| e.deep_clone}
  end
  
  def deep_freeze
    each {|e| e.deep_freeze}
    freeze
  end
  
  def rand
    empty? ? nil : self[Kernel::rand(size)]
  end
  
  def sorted_inspect
    '[' + map{|k|k.inspect}.sort.join(', ') + ']'
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
  
  def |(h2)
    h2.merge(self)
  end
  
  def deep_clone
    x= {}
    each {|k,v| x[k.deep_clone]= v.deep_clone}
    x
  end
  
  def deep_freeze
    each {|k,v|
      k.deep_freeze
      v.deep_freeze
    }
    freeze
  end
  
  # Default inspect doesn't sort by key
  def inspect
    '{' + keys.map{|k|[k.inspect,k]}.sort{|a,b|a[0]<=>b[0]}.map{|ki,k| "#{ki}=>#{self[k].inspect}"}.join(', ') + '}'
  end
end


#===========================
# Strings + Symbols

class String
  alias :old_cmp :<=>
  def <=>(o)
    if o.is_a?(Symbol)
      1
    else
      old_cmp o
    end
  end
end

class Symbol
  def <=>(o)
    if o.is_a?(Symbol)
      self.to_s <=> o.to_s
    else
      -1
    end
  end
end


#===========================
# Numbers

module BitManipulation
  def set_bit(bit,on)
    if on
      self | (1<<bit)
    else
      self & ~(1<<bit)
    end
  end
end

Fixnum.send :include, BitManipulation
Bignum.send :include, BitManipulation


#===========================
# Module + Class

class Module
  def get_all_subclasses_of(klass)
    constants.sort.map{|c| module_eval c}.select{|c|c.is_a?(Class) && c.superclass == klass}
  end
  
  def freeze_all_constants
    clist= constants
    clist-= included_modules.map{|m|m.constants}.flatten
    clist-= superclass.constants if self.class == Class
    clist.each{|c|const_get(c).deep_freeze}
  end
end
