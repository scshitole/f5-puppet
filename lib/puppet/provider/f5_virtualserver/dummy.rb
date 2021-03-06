require File.join(File.dirname(__FILE__), '../f5')

Puppet::Type.type(:f5_virtualserver).provide(:dummy, :parent => Puppet::Provider::F5) do
  desc "Dummy default provider"

  defaultfor :feature => :f5_device
  def self.instances
    []
  end

  def exists?
    providers = @resource.class.providers.map{|x| x.to_s}.sort.reject{|x| x == "dummy"}.join(", ") rescue "none"
    raise("f5_virtualserver requires that a provider is declared. Available providers are: #{providers}")
  end
end
