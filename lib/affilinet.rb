require 'rubygems'
require 'savon'

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

  LOGON_SERVICE = '/V2.0/Logon.svc?wsdl'

  SERVICES.each do |key, wsdl|
    define_method(key) do
      AffilinetAPI::API::WebService.new(wsdl, @user, @password, @base_url)
    end
  end

  # set the base_url and credentials
  #
  def initialize(user, password, options = {})
    @base_url = if options[:developer]
                  'https://developer-api.affili.net'
                else
                  'https://api.affili.net'
                end
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
    # TODO we don't want ...RequestMessage for the creative service
    # consequently those services don't work
    def method_missing(method, *args)
      if operations_include?(method)
        op = operation(method)
        if method == :get_payments || method == :search_creatives
          op.body = {
            "#{method.to_s.camelize}Request" => {
              'CredentialToken' => token,
            }.merge(args.first)
          }
        else
          op.body = {
            "#{method.to_s.camelize}Request" => {
              'CredentialToken' => token,
              "#{method.to_s.camelize}RequestMessage" => args.first
            }
          }
        end
        res = op.call
        Hashie::Mash.new res.body.values.first
      else
        super
      end
    end

    protected

      # only return a new driver if no one exists already
      #
      def driver
        @driver ||= Savon.new(@base_url + @wsdl)
      end

      def logon_driver
        @logon_driver ||= Savon.new(@base_url + LOGON_SERVICE)
      end

      # returns actual token or a new one if expired
      #
      def token
        if (@token && @created > 20.minutes.ago)
          return @token
        end
        @created = Time.now
        @token = fresh_token
      end

      def fresh_token
        operation = logon_driver
          .operation('Authentication', 'DefaultEndpointLogon', 'Logon')
        operation.body = logon_body
        response = operation.call
        response.body[:credential_token]
      end

      def logon_body
        {
          LogonRequestMsg: {
            'Username' => @user,
            'Password' => @password,
            'WebServiceType' => 'Publisher',
            'DeveloperSettings' => {
              :SandboxPublisherID => ENV['AFFILINET_SANDBOXPUBLISHERID'].dup
            }
          }
        }

      end

      def operations_include?(method)
        operations.include? api_method(method)
      end

      def operations
        driver.operations(service, port)
      end

      def operation(method)
        driver.operation service, port, api_method(method)
      end

      def services
        driver.services
      end

      def service
        services.keys.first
      end

      def port
        port = services.values.first[:ports].keys.first
      end

      # handles the special name case of getSubIDStatistics
      #
      def api_method(method)
        method.to_s.camelize.sub 'GetSubIdStatistics', 'GetSubIDStatistics'
      end
    end
  end
end
