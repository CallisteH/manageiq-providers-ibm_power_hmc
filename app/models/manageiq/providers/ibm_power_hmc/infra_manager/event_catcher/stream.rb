class ManageIQ::Providers::IbmPowerHmc::InfraManager::EventCatcher::Stream
  class ProviderUnreachable < ManageIQ::Providers::BaseManager::EventCatcher::Runner::TemporaryFailure
  end

  def initialize(ems, options = {})
    @ems = ems
    @last_activity = nil
    @stop_polling = false
    @poll_sleep = options[:poll_sleep] || 20.seconds
  end

  def start
    @stop_polling = false
  end

  def stop
    @stop_polling = true
  end

  def poll
    @ems.with_provider_connection do |connection|
      catch(:stop_polling) do
        loop do
          connection.next_events.each do |event|
            throw :stop_polling if @stop_polling
            yield event
          end
        end
      rescue => exception
        raise ProviderUnreachable, exception.message
      end
    end
  end
end
