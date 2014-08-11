require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_monitor).provide(:https, parent: Puppet::Provider::F5) do

  def initialize(value={})
    super(value)
    @create_elements = false
  end

  def self.instances
    instances = []
    monitors = Puppet::Provider::F5.call('/mgmt/tm/ltm/monitor/https')
    monitors.each do |monitor|
      aliasAddress, aliasServicePort = monitor['destination'].split(':')
      instances << new(
        ensure:                :present,
        alias_address:          aliasAddress,
        alias_service_port:     aliasServicePort,
        cipher_list:            monitor['cipherlist'],
        client_certificate:     monitor['cert'],
        client_key:             monitor['key'],
        compatibility:          monitor['compatibility'],
        description:            monitor['description'],
        interval:               monitor['interval'],
        manual_resume:          monitor['manualResume'],
        name:                   monitor['fullPath'],
        password:               monitor['password'],
        receive_disable_string: monitor['recvDisable'],
        receive_string:         monitor['recv'],
        reverse:                monitor['reverse'],
        send_string:            monitor['send'],
        time_until_up:          monitor['timeUntilUp'],
        timeout:                monitor['timeout'],
        transparent:            monitor['transparent'],
        up_interval:            monitor['upInterval'],
        username:               monitor['username'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |node| node.name == name }
        resources[name].provider = provider
      end
    end
  end

  def basename
    File.basename(resource[:name])
  end

  def partition
    File.dirname(resource[:name])
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'send-string'            => :send,
      :'receive-string'         => :recv,
      :'receive-disable-string' => :recvDisable,
      :'cipher-list'            => :cipherlist,
      :'client-certificate'     => :cert,
      :'client-key'             => :key,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)
    message = string_to_integer(message)
    message = monitor_conversion(message)
    message = destination_conversion(message)
    elements_to_strip = [:'alias-address', :'alias-service-port']
    message = strip_elements(message, elements_to_strip)

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/monitor/https/#{basename}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @create_elements = true
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/monitor/https", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/monitor/https/#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end