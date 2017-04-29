module KubernetesCookbook
  # Helper to generate commandline flags from resource properties
  class CommandGenerator
    def initialize(binary, resource)
      @binary = binary
      @resource = resource
    end

    def generate
      actual_flags = list_commandline_flag_properties.map do |property, _|
        value = @resource.send(property)
        value = value.join ',' if value.is_a? Array
        "--#{property.to_s.tr('_', '-')}=#{value}"
      end
      actual_flags.reduce @binary do |command, flag|
        command << " #{flag}"
      end
    end

    private

    def non_commandline_property?(property)
      [
        :name, :run_user, :remote, :checksum,
        :container_runtime_service
      ].include? property
    end

    def list_commandline_flag_properties
      @resource.class.properties.reject do |property, description|
        value = @resource.send(property)
        non_commandline_property?(property) || (value == description.default)
      end
    end
  end
end
