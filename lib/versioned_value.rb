class VersionedValue
  require 'java'

  attr_reader :value
  attr_reader :version

  def initialize(hotrod_versioned)
    @value = Marshal.load(hotrod_versioned.getValue)
    @version = hotrod_versioned.getVersion
  end

  def to_s
    "Value = #{@value}, Version=#{@version}"
  end

  def ==(another_inst)
    self.version == another_inst.version
    self.value == another_inst.value
  end

end