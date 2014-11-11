module ProvidersForeman
  class Connection
    # url for foreman host. just a hostname works fine
    # I am here  I
    attr_accessor :base_url
    attr_accessor :username
    attr_accessor :password

    # defaults to OpenSSL::SSL::VERIFY_PEER
    # for self signed certs, probably want to do:
    # OpenSSL::SSL::VERIFY_NONE (0 / false)
    attr_accessor :verify_ssl

    def initialize(opts = {})
      opts.each do |n, v|
        public_send("#{n}=", v)
      end
    end

    def verify_ssl=(val)
      @verify_ssl = if val == true
                      OpenSSL::SSL::VERIFY_PEER
                    elsif val == false
                      OpenSSL::SSL::VERIFY_NONE
                    else
                      val
                    end
    end

    def verify_ssl?
      @verify_ssl != OpenSSL::SSL::VERIFY_NONE
    end

    def api_version
      home.status.first["api_version"]
    end

    def hosts
      raw_hosts.index.first["results"]
    end

    def denormalized_host_groups
      denormalize_host_groups(host_groups)
    end

    def host_groups
      raw_host_groups.index.first["results"]
    end

    def operating_systems(filter = nil)
      paged_response(ForemanApi::Resources::OperatingSystem, filter)
    end

    def media(filter = nil)
      paged_response(ForemanApi::Resources::Medium, filter)
    end

    def ptable(filter = nil)
      paged_response(ForemanApi::Resources::Ptable, filter)
    end

    # take all the data from ancestors, and put that into the groups
    def denormalize_host_groups(groups)
      groups.collect do |g|
        (g["ancestry"] || "").split("/").each_with_object({}) do |gid, h|
          h.merge!(groups.detect {|gd| gd["id"].to_s == gid }.select { |_n, v| !v.nil? })
        end.merge!(g.select { |_n, v| !v.nil? })
      end
    end

    # future meta foo
    # results(ForemanApi::Resources::Host)
    def paged_response(resource, filter = {})
      PagedResponse.new(raw(resource).index.first, filter)
    end

    def update_record(resource, values)
      PagedResponse.new(raw(resource).update(values).first)
    end

    def raw_home
      ForemanApi::Resources::Home.new(connection_attrs)
    end

    def raw_hosts
      ForemanApi::Resources::Host.new(connection_attrs)
    end

    def raw_host_groups
      ForemanApi::Resources::Hostgroup.new(connection_attrs)
    end

    private

    def raw(resource)
      resource.new(connection_attrs)
    end

    def connection_attrs
      {
        :base_url   => @base_url,
        :username   => @username,
        :password   => @password,
        :verify_ssl => @verify_ssl
      }
    end
  end
end
