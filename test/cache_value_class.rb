# To change this template, choose Tools | Templates
# and open the template in the editor.

class CacheValueClass

  attr_reader :t1
  attr_reader :t2

  def initialize(a, b)
    @t1 = a
    @t2 = b
  end

  def ==(another_inst)
    self.t1 == another_inst.t1
    self.t2 == another_inst.t2
  end

  def to_s
    "t1=#{@t1} t2=#{@t2}"
  end
end
