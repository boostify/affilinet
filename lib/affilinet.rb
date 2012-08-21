require 'rubygems'
gem 'soap4r'
require 'soap_mapping_object_extension'
require 'soap/wsdlDriver'

module AffilinetAPI
  class API

  # create a new webservice for each wsdl
  SERVICES = {
    :creative => '/V2.0/PublisherCreative.svc?wsdl',
    :product => '/V2.0/ProductServices.svc?wsdl',
    :inbox => '/V2.0/PublisherInbox.svc?wsdl',
    :account => '/V2.0/AccountService.svc?wsdl',
    :statistics => '/V2.0/PublisherStatistics.svc?wsdl',
    :program_list => '/V2.0/PublisherProgram.svc?wsdl'
  }
  SERVICES.each do |key, wsdl|
    define_method(key) do
      AffilinetAPI::API::WebService.new(wsdl, @user, @password, @base_url)
    end
  end

  # set the base_url and credentials
  #
  def initialize(user, password, options = {})
    @base_url = options[:developer] ? 'https://developer-api.affili.net' : 'https://api.affili.net'
    @user = user
    @password = password
  end

  class WebService

    def initialize(wsdl, user, password, url)
      @wsdl = wsdl
      @user = user.dup
      @password = password.dup
      @base_url = url
    end

    # checks against the wsdl if method is supported and raises an error if not
    #
      def method_missing(method, *args)
        if get_driver.respond_to?(api_method(method))
          arguments = { 'CredentialToken' => get_valid_token, "#{method.to_s.camelize}RequestMessage" => args.first }
          # we don't want ...RequestMessage for the creative service
          if (@wsdl == AffilinetAPI::API::SERVICES[:creative]) ||
            (@wsdl == AffilinetAPI::API::SERVICES[:account])
            arguments.merge!(args.first)
          end
          get_driver.send(api_method(method), arguments)
        else
          super
        end
      end

      protected

      # only return a new driver if no one exists already
      #
      def get_driver
        @driver ||= soap_driver(@wsdl)
      end

      def soap_driver(wsdl)
        driver = SOAP::WSDLDriverFactory.new(@base_url + wsdl).create_rpc_driver
        driver.wiredump_dev = STDOUT if $DEBUG
        driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
        driver
      end

      # returns actual token or a new one if expired
      #
      def get_valid_token
        return @token if (@token and (@created > 20.minutes.ago))
        @token = soap_driver("/V2.0/Logon.svc?wsdl").logon({
            :Username => @user,
            :Password => @password,
            :WebServiceType => 'Publisher',
            :DeveloperSettings => { :SandboxPublisherID => ENV['AFFILINET_SANDBOXPUBLISHERID'].dup }
          })
        @created = Time.now
        @token
      end

      # handles the special name case of getSubIDStatistics
      #
      def api_method(method)
        method = method.to_s.camelize
        method == "GetSubIdStatistics" ? "GetSubIDStatistics" : method
      end

    end
  end
end

