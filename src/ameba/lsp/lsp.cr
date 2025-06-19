require "larimar/api/provider_server"

module Ameba::Lsp
  def self.run
    server = Larimar::Server.new(STDIN, STDOUT)

    backend = Larimar::LogBackend.new(server, formatter: Larimar::LogFormatter)
    ::Log.setup_from_env(backend: backend)

    controller = Larimar::ProviderController.new
    controller.register_provider(Lsp::Provider.new)

    server.start(controller)
  end
end
