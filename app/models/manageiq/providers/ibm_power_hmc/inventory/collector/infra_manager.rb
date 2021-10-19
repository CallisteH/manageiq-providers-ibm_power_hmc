class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector
  def initialize(manager, target)
    super
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @cecs = connection.managed_systems

      @lpars = @cecs.map do |sys|
        connection.lpars(sys.uuid)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("lpars query failed for #{sys.uuid}: #{e}")
        nil
      end.flatten.compact
      
      @vswitches = @cecs.map do |sys|
        connection.virtual_switches(sys.uuid)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("virtual_switches query failed for #{sys.uuid} reason=#{e.reason} message=#{e.message}")
      end

      @vioses = @cecs.map do |sys|
        connection.vioses(sys.uuid)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("vioses query failed for #{sys.uuid} #{e}")
        nil
      end.flatten.compact

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
    @vswitches || []
  end

  private

  def vioses
    @vioses || []
  end
end
