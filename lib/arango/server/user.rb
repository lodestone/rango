module Arango
  class Server
    module User
      # === USER ===

      def user(password: "", name:, extra: {}, active: nil)
        Arango::User.new(host: self, password: password, name: name, extra: extra,
                         active: active)
      end

      def users
        result = request("GET", "_api/user", key: :result)
        return result if return_directly?(result)
        result.map do |user|
          Arango::User.new(name: user[:user], active: user[:active],
                           extra: user[:extra], host: self)
        end
      end

    end
  end
end
