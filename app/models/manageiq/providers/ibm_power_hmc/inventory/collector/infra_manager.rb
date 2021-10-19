class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector
  def initialize(manager, target)
    super
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    @hosts = connection.managed_systems
    @vms = []
    @vswitches = []
    @hosts.each do |sys|
      @vms += connection.lpars(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("lpars query failed for #{sys.uuid} reason=#{e.reason} message=#{e.message}")
    end
    @hosts.each do |sys|
      @vms += connection.vioses(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("vioses query failed for #{sys.uuid} reason=#{e.reason} message=#{e.message}")
    end
    @hosts.each do |sys|
      @vswitches += connection.virtual_switches(sys.uuid)
    rescue IbmPowerHmc::Connection::HttpError => e
      $ibm_power_hmc_log.error("virtual_switches query failed for #{sys.uuid} reason=#{e.reason} message=#{e.message}")
    end
    connection.logoff
    $ibm_power_hmc_log.info("end collection")
  rescue IbmPowerHmc::Connection::HttpError => e
    $ibm_power_hmc_log.error("managed systems query failed reason=#{e.reason} message=#{e.message}")
  ensure
    # Make sure we do not leak HMC sessions
    connection.logoff
  end

  def hosts
    @hosts || []
  end

  def vms
    @vms || []
  end

  def vswitches
    @vswitches || []
  end

  private

  def connection
    @connection ||= manager.connect
  end
end
