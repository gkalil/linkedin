module LinkedIn
  module Helpers

    module Request

      DEFAULT_HEADERS = {
        'x-li-format' => 'json'
      }

      API_PATH = '/v1'

      protected

        def get(path, options={})
          response = access_token.get("#{API_PATH}#{path}", DEFAULT_HEADERS.merge(options))
          raise_errors(response)
          response.body
        end

        def post(path, body='', options={})
          response = access_token.post("#{API_PATH}#{path}", body, DEFAULT_HEADERS.merge(options))
          raise_errors(response)
          response
        end

        def put(path, body, options={})
          response = access_token.put("#{API_PATH}#{path}", body, DEFAULT_HEADERS.merge(options))
          raise_errors(response)
          response
        end

        def delete(path, options={})
          response = access_token.delete("#{API_PATH}#{path}", DEFAULT_HEADERS.merge(options))
          raise_errors(response)
          response
        end

      private

        def raise_errors(response)
          # Even if the json answer contains the HTTP status code, LinkedIn also sets this code
          # in the HTTP answer (thankfully).
          case response.code.to_i
          when 401
            data = Mash.from_json(response.body)
            raise UnauthorizedError.new(data), "(#{data.status}): #{data.message}"
          when 400, 403
            data = Mash.from_json(response.body)
            raise GeneralError.new(data), "(#{data.status}): #{data.message}"
          when 404
            raise NotFoundError, "(#{response.code}): #{response.message}"
          when 500
            raise InformLinkedInError, "LinkedIn had an internal error. Please let them know in the forum. (#{response.code}): #{response.message}"
          when 502..503
            raise UnavailableError, "(#{response.code}): #{response.message}"
          end
        end

        def to_query(options)
          options.inject([]) do |collection, opt|
            collection << "#{opt[0]}=#{opt[1]}"
            collection
          end * '&'
        end

        def to_uri(path, options)
          uri = URI.parse(path)

          if options && options != {}
            uri.query = to_query(options)
          end
          uri.to_s
        end
        
        def field_selector(fields)
          result = ":("
          fields.to_a.map! do |field|
            if field.is_a?(Hash)
              innerFields = []
              field.each do |key, value|
                innerFields << key.to_s.gsub("_","-") + field_selector(value)
              end
              innerFields.join(',')
            else
              field.to_s.gsub("_","-")
            end
          end
          result += fields.join(',')
          result += ")"
          result
        end
        
        def format_options_for_query(opts)
          opts.inject({}) do |list, kv|
            key, value = kv.first.to_s.gsub("_","-"), kv.last
            list[key]  = sanatize_value(value)
            list
          end
        end

        def sanatize_value(value)
          value = value.join("+") if value.is_a?(Array)
          value = value.gsub(" ", "+") if value.is_a?(String)
          value
        end
    end

  end
end