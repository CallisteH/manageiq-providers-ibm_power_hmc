class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector
  def initialize(manager, target)
    super
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @cecs = connection.managed_systems
      do_lpars(connection)
      do_vioses(connection)
      do_vswitches(connection)
      do_vlans(connection)
      $ibm_power_hmc_log.info("end collection")
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("managed systems query failed: #{e}")
    end
  end

  def cecs
    @cecs || []
  end

  def lpars
    @lpars || []
  end

  def vswitches
    @vswitches || {}
  end

  def vlans
    @vlans || {}
  end

  def vioses
    @vioses || []
  end

  def netadapters
    @netadapters || {}
  end

  private

  #Get all vlans from all managed systems(cecs)
  def do_vlans(connection)
    @vlans = {}
    @cecs.each do |sys|
      @vlans[sys.uuid] = connection.virtual_networks(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("virtual_networks query failed for #{sys.uuid}: #{e}")
    end
  end

  def do_vswitches(connection)
    @vswitches = {}
    @cecs.each do |sys|
      @vswitches[sys.uuid] = connection.virtual_switches(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("virtual_switches query failed for #{sys.uuid}: #{e}")
    end
  end

  def do_lpars(connection)
    @lpars = @cecs.map do |sys|
      connection.lpars(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("lpars query failed for #{sys.uuid}: #{e}")
      nil
    end.flatten.compact

    @netadapters = {}
    @lpars.each do |lpar|
      lpar.net_adap_uuids.each do |net_adap_uuid|
        @netadapters[net_adap_uuid] = connection.network_adapter_lpar(lpar.uuid, net_adap_uuid)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("network adapter query failed for #{lpar.uuid}/#{net_adap_uuid}: #{e}")
      end
    end
  end

  def do_vioses(connection)
    @vioses = @cecs.map do |sys|
      connection.vioses(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("vioses query failed for #{sys.uuid} #{e}")
      nil
    end.flatten.compact

    @vioses.each do |vios|
      vios.net_adap_uuids.each do |net_adap_uuid|
        @netadapters[net_adap_uuid] = connection.network_adapter_vios(vios.uuid, net_adap_uuid)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("network adapter query failed for #{vios.uuid}/#{net_adap_uuid}: #{e}")
      end
    end
  end
end
