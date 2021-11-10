class ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::TargetCollection < ManageIQ::Providers::IbmPowerHmc::Inventory::Collector::InfraManager
  def initialize(_manager, _target)
    super

    parse_targets!
  end

  def collect!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
  end

  def cecs
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @cecs ||= references(:hosts).map do |ems_ref|
        connection.managed_system(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying managed system #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact

      @vswitches ||= {}
      @vlans ||= {}
      @cecs.each do |cec|
        @vswitches[cec.uuid] = connection.virtual_switches(cec.uuid)
        @vlans[cec.uuid] = connection.virtual_networks(cec.uuid)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying virtual_switches or virtual_networks for managed system  #{cec.uuid}: #{e}") unless e.status == 404
      end 
    end
  end

  def lpars
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @lpars ||= references(:vms).map do |ems_ref|
        connection.lpar(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying lpar #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact

      @netadapters ||= {}
      @lpars.each do |lpar|
        lpar.net_adap_uuids.each do |net_adap_uuid|
          @netadapters[net_adap_uuid] = connection.network_adapter_lpar(lpar.uuid, net_adap_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("network adapter query failed for #{lpar.uuid}/#{net_adap_uuid}: #{e}")
        end
      end
    end
    @lpars || []
  end

  def vioses
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")
    manager.with_provider_connection do |connection|
      @vioses ||= references(:vms).map do |ems_ref|
        connection.vios(ems_ref)
      rescue IbmPowerHmc::Connection::HttpError => e
        $ibm_power_hmc_log.error("error querying vios #{ems_ref}: #{e}") unless e.status == 404
        nil
      end.compact

      @netadapters ||= {}
      @vioses.each do |vios|
        vios.net_adap_uuids.each do |net_adap_uuid|
          @netadapters[net_adap_uuid] = connection.network_adapter_vios(vios.uuid, net_adap_uuid)
        rescue IbmPowerHmc::Connection::HttpError => e
          $ibm_power_hmc_log.error("network adapter query failed for #{vios.uuid}/#{net_adap_uuid}: #{e}")
        end
      end
    end
    @vioses || []
  end

  def netadapters
    @netadapters || {}
  end

  def vswitches
    @vswitches || {}
  end

  def vlans
    @vlans || {}
  end

  private

  def parse_targets!
    $ibm_power_hmc_log.info("#{self.class}##{__method__}")

    target.targets.each do |target|
      case target
      when Host
        add_target(:hosts, target.ems_ref)
      when ManageIQ::Providers::IbmPowerHmc::InfraManager::Lpar, ManageIQ::Providers::IbmPowerHmc::InfraManager::Vios
        add_target(:vms, target.ems_ref)
      when HostSwitch
        add_target(:host_virtual_switches, target.ems_ref)
      when Lan
        add_target(:lans, target.ems_ref)
      else
        $ibm_power_hmc_log.info("#{self.class}##{__method__} WHAT IS THE CLASS NAME ? #{target.class.name} ")
      end
    end
  end

  def add_target(association, ems_ref)
    return if ems_ref.blank?

    target.add_target(:association => association, :manager_ref => {:ems_ref => ems_ref})
  end

  def references(collection)
    target.manager_refs_by_association&.dig(collection, :ems_ref)&.to_a&.compact || []
  end
end
