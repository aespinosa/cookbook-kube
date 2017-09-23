# Copyright 2016-2017 Allan Espinosa
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
        :name, :run_user, :remote, :checksum, :version,
        :container_runtime_service, :file_ulimit
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
