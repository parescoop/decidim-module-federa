module OneLogin
  module RubySaml

    class Response < SamlMessage

      def validate_num_assertion
        error_msg = "SAML Response must contain 1 assertion"
        assertions = REXML::XPath.match(
          document,
          "//p:Response/a:Assertion",
          { "a" => ASSERTION, "p" => PROTOCOL }
        )
        encrypted_assertions = REXML::XPath.match(
          document,
          "//a:EncryptedAssertion",
          { "a" => ASSERTION }
        )

        unless assertions.size + encrypted_assertions.size == 1
          return append_error(error_msg)
        end

        unless decrypted_document.nil?
          assertions = REXML::XPath.match(
            decrypted_document,
            "//a:Assertion",
            { "a" => ASSERTION }
          )
          unless assertions.size == 1
            return append_error(error_msg)
          end
        end

        true
      end

    end
  end
end